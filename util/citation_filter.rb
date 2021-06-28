# frozen_string_literal: true

require 'addressable'
require 'sinatra'

require_relative '../database/models'
require_relative '../fhir/fhir_adapter'

# Helper methods for CEDAR API
class CitationFilter
  def initialize(params:, base_url:, request_url:)
    @params = params
    @artifact_base_url = base_url
    @request_url = request_url
  end

  def build_link_url(page_no, page_size)
    uri = Addressable::URI.parse(@request_url)
    new_params = @params.reject { |key, _value| %w[_count page].include?(key) }

    if page_size.positive?
      new_params[:_count] = page_size
      new_params[:page] = page_no if page_no.positive?
    end

    uri.query_values = new_params
    uri.normalize.to_str
  end

  def citations
    filter = build_filter

    paged_result = add_pagination(filter)

    artifacts = paged_result[:artifacts]
    total = paged_result[:total]

    bundle = if @page_size.zero?
               # if _count=0, return count only
               FHIRAdapter.create_citation_bundle(total: total)
             else
               FHIRAdapter.create_citation_bundle(total: total, artifacts: artifacts, base_url: @artifact_base_url)
             end

    add_bundle_links(bundle, artifacts)

    bundle
  end

  def build_filter
    filter = Artifact.join(:repositories, id: :repository_id)

    @params&.each do |key, value|
      search_terms = value.split(',').map { |v| v.strip.downcase.to_s }

      case key
      when '_content'
        cols = SearchParser.parse(value)
        opt = {
          language: 'english',
          rank: true,
          tsvector: true
        }

        filter = filter.full_text_search(:content_search, cols, opt)
      when 'classification'
        cols = SearchParser.parse(value)
        opt = {
          language: 'english',
          rank: true
        }

        # Need to decide if we need use ts_vector to get better performance
        filter = filter.full_text_search([:keyword_text, :mesh_keyword_text], cols, opt)
      when 'title'
        search_terms.map! { |t| "#{t}%" }
        filter = append_boolean_expression(:ILIKE, :title, search_terms, filter)
      when 'title:contains'
        search_terms.map! { |t| "%#{t}%" }
        filter = append_boolean_expression(:ILIKE, :title, search_terms, filter)
      when 'artifact-current-state'
        filter = filter.where(artifact_status: search_terms)
      when 'artifact-publisher'
        filter = filter.where { |o| { o.lower(:fhir_id) => search_terms } }
      end
    end

    filter
  end

  def add_pagination(filter)
    @page_size = (@params['_count'] || -1).to_i
    @page_no = [(@params['page'] || 1).to_i, 1].max # the minimum value of page number is 1

    if @page_size.positive?
      # if page size is greater than 0, return paginated results.
      artifacts = filter.paginate(@page_no, @page_size)
      total = artifacts.pagination_record_count
    elsif @page_size.zero?
      # if page size is 0, return the count only
      artifacts = nil
      total = filter.count
    else
      # otherwise (page size is less than 0), return all results
      artifacts = filter.all
      total = artifacts.size
    end

    {
      artifacts: artifacts,
      total: total
    }
  end

  def add_bundle_links(bundle, artifacts)
    bundle.link << FHIR::Bundle::Link.new(
      {
        relation: 'self',
        url: build_link_url(@page_no, @page_size)
      }
    )

    # full seach result does not have first/last/prev/next page link (page_size = -1)
    return unless @page_size.positive?

    # add first/last page link
    bundle.link << FHIR::Bundle::Link.new(
      {
        relation: 'first',
        url: build_link_url(1, @page_size)
      }
    )

    bundle.link << FHIR::Bundle::Link.new(
      {
        relation: 'last',
        url: build_link_url(artifacts.page_count, @page_size)
      }
    )

    # first page does not have prev page
    unless artifacts.first_page?
      bundle.link << FHIR::Bundle::Link.new(
        {
          relation: 'prev',
          url: build_link_url(@page_no - 1, @page_size)
        }
      )
    end

    # last page does not have next page
    unless artifacts.last_page?
      bundle.link << FHIR::Bundle::Link.new(
        {
          relation: 'next',
          url: build_link_url(@page_no + 1, @page_size)
        }
      )
    end
  end

  def append_boolean_expression(operator, target, search_terms, filter)
    if search_terms.length == 1
      filter = filter.where(Sequel::SQL::BooleanExpression.new(operator, target, search_terms.first))
    elsif search_terms.length > 1
      args = search_terms.map { |term| Sequel::SQL::BooleanExpression.new(operator, target, term) }
      filter = filter.where(Sequel::SQL::BooleanExpression.new(:OR, *args))
    end
    filter
  end
end
