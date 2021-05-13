# frozen_string_literal: true

require 'addressable'
require 'sinatra'

require_relative '../database/models'
require_relative '../fhir/fhir_adapter'

# Helper methods for CEDAR API
class ApiHelper
  def self.build_next_page_url(request, page_no = 0, page_size = 0)
    uri = Addressable::URI.parse("#{request.scheme}://#{request.host}:#{request.port}#{request.path}")
    params = {}

    request.params.each do |key, value|
      next if %w[_count page].include?(key)

      params[key.to_sym] = value
    end

    if page_size.positive?
      params[:_count] = page_size
      params[:page] = page_no if page_no.positive?
    end

    uri.query_values = params
    uri.normalize.to_str
  end

  def self.find_citation(params, artifact_base_url, request)
    filter = Artifact.join(:repositories, id: :repository_id)
    page_size = -1
    page_no = 1

    # artifact-current-state is required
    unless params&.any? { |key, _value| key == 'artifact-current-state' }
      oo = FHIR::OperationOutcome.new(
        issue: [
          {
            severity: 'error',
            code: 'required',
            details: {
              text: 'Required search parameter artifact-current-state is missing'
            }
          }
        ]
      )

      return oo
    end

    params&.each do |key, value|
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
        search_terms = value.split(',').map { |v| v.strip.downcase.to_s }
        search_terms.map! { |t| "#{t}%" }
        filter = append_boolean_expression(:ILIKE, :title, search_terms, filter)
      when 'title:contains'
        search_terms = value.split(',').map { |v| v.strip.downcase.to_s }
        search_terms.map! { |t| "%#{t}%" }
        filter = append_boolean_expression(:ILIKE, :title, search_terms, filter)
      when 'artifact-current-state'
        search_terms = value.split(',').map { |v| v.strip.downcase.to_s }
        filter = filter.where(artifact_status: search_terms)
      when 'artifact-publisher'
        search_terms = value.split(',').map { |v| v.strip.downcase.to_s }
        filter = filter.where { |o| { o.lower(:fhir_id) => search_terms } }
      when '_count'
        page_size = value.to_i
      when 'page'
        page_no = value.to_i
        page_no = 1 if page_no < 1
      end
    end

    # return count only
    return FHIRAdapter.create_citation_bundle(nil, artifact_base_url, filter.count, true) if page_size.zero?

    # if page size is greater than 0, return paginated results.
    # otherwise, return all results
    if page_size.positive?
      artifacts = filter.paginate(page_no, page_size)
      total = artifacts.pagination_record_count
    else
      artifacts = filter.all
      total = artifacts.size
    end

    bundle = FHIRAdapter.create_citation_bundle(artifacts, artifact_base_url, total, page_size.zero?)

    bundle.link << FHIR::Bundle::Link.new(
      {
        relation: 'self',
        url: ApiHelper.build_next_page_url(request, page_no, page_size)
      }
    )

    # add link if request is not count only
    if page_size.positive?
      bundle.link << FHIR::Bundle::Link.new(
        {
          relation: 'first',
          url: ApiHelper.build_next_page_url(request, 1, page_size)
        }
      )

      bundle.link << FHIR::Bundle::Link.new(
        {
          relation: 'last',
          url: ApiHelper.build_next_page_url(request, artifacts.page_count, page_size)
        }
      )

      # first page does not have prev page
      unless artifacts.first_page?
        bundle.link << FHIR::Bundle::Link.new(
          {
            relation: 'prev',
            url: ApiHelper.build_next_page_url(request, page_no - 1, page_size)
          }
        )
      end

      # last page does not have next page
      unless artifacts.last_page?
        bundle.link << FHIR::Bundle::Link.new(
          {
            relation: 'next',
            url: ApiHelper.build_next_page_url(request, page_no + 1, page_size)
          }
        )
      end
    end

    bundle
  end

  def self.append_boolean_expression(operator, target, search_terms, filter)
    if search_terms.length == 1
      filter = filter.where(Sequel::SQL::BooleanExpression.new(operator, target, search_terms.first))
    elsif search_terms.length > 1
      args = search_terms.map { |term| Sequel::SQL::BooleanExpression.new(operator, target, term) }
      filter = filter.where(Sequel::SQL::BooleanExpression.new(:OR, *args))
    end
    filter
  end
end
