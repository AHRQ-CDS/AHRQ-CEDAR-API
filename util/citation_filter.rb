# frozen_string_literal: true

require 'addressable'
require 'time'
require 'date'
require 'active_support/core_ext/numeric/time'
require 'sinatra'

require_relative '../database/models'
require_relative '../fhir/fhir_adapter'
require_relative 'errors'

# Helper methods for CEDAR API
class CitationFilter
  UMLS_CODE_SYSTEM_IDS = FHIRAdapter::FHIR_CODE_SYSTEM_URLS.invert.freeze

  def initialize(params:, base_url:, request_url:, client_ip: nil, log_to_db: false)
    @artifact_base_url = base_url
    @request_url = request_url
    @client_ip = client_ip
    @log_to_db = log_to_db

    @search_log = SearchLog.new
    @search_log.search_params = params
    @search_log.client_ip = client_ip
  end

  def build_link_url(page_no, page_size)
    uri = Addressable::URI.parse(@request_url)
    new_params = @search_log.search_params.reject { |key, _value| %w[_count page].include?(key) }

    if page_size.positive?
      new_params[:_count] = page_size
      new_params[:page] = page_no if page_no.positive?
    end

    uri.query_values = new_params
    uri.normalize.to_str
  end

  def get_artifacts_with_concept(system_and_code)
    system, code = system_and_code.split('|').map { |v| v.strip.to_s }
    if code.nil?
      code = system
      system = nil
    end
    synonyms_op = Sequel.pg_jsonb_op(:codes)
    concepts = if system.nil?
                 Concept.where(synonyms_op.contains([{ 'code': code }]))
               else
                 Concept.where(synonyms_op.contains([{ 'system': UMLS_CODE_SYSTEM_IDS[system], 'code': code }]))
               end
    concepts.map { |c| c.artifacts.collect(&:id) }.flatten.uniq
  end

  def citations
    @search_log.start_time = Time.now

    filter = build_filter

    begin
      paged_result = add_pagination(filter)
    rescue StandardError => e
      raise DatabaseError.new(message: e.message)
    end

    artifacts = paged_result[:artifacts]
    total = paged_result[:total]

    bundle = if @page_size.zero?
               # if _count=0, return count only
               FHIRAdapter.create_citation_bundle(total: total)
             else
               FHIRAdapter.create_citation_bundle(total: total, artifacts: artifacts, base_url: @artifact_base_url)
             end

    add_bundle_links(bundle, artifacts)

    if @log_to_db
      @search_log.count = artifacts.count unless @page_size.zero?
      @search_log.total = total
      @search_log.end_time = Time.now

      begin
        @search_log.save_changes
        @search_log.search_parameter_logs.each do |p|
          p.search_log = @search_log
          p.save_changes
        end
      rescue StandardError
        # We should continue the workflow if logging failed.
        # Do we need to log to somewhere that logging failed?
      end
    end

    bundle
  end

  def build_filter
    # Don't join other tables here since:
    # 1. Their id columns override the artifact id and that causes problems using the Sequel models
    #    that rely on id joins
    # 2. The many-to-many relationship with concepts results in multiple rows per artifact
    filter = Artifact.dataset

    @search_log.search_params&.each do |key, value|
      search_terms = value.split(',').map { |v| v.strip.downcase.to_s }

      begin
        case key
        when '_content'
          @search_log.search_parameter_logs << SearchParameterLog.new(name: key, value: value)

          cols = SearchParser.parse(value)
          opt = {
            language: 'english',
            rank: true,
            tsvector: true
          }

          filter = filter.full_text_search(:content_search, cols, opt)
        when '_lastUpdated'
          @search_log.search_parameter_logs << SearchParameterLog.new(name: key, value: value)
          postgres_search_terms = self.class.fhir_datetime_to_postgres_search(value)
          filter = filter.where(Sequel.lit(*postgres_search_terms))
        when 'classification'
          @search_log.search_parameter_logs << SearchParameterLog.new(name: key, value: value)
          artifact_ids = get_artifacts_with_concept(value)
          filter = filter.where(Sequel[:artifacts][:id] => artifact_ids)
        when 'classification:text'
          @search_log.search_parameter_logs << SearchParameterLog.new(name: key, value: value)
          cols = SearchParser.parse(value)
          opt = {
            language: 'english',
            rank: true
          }

          # Need to decide if we need use ts_vector to get better performance
          filter = filter.full_text_search(:keyword_text, cols, opt)
        when 'title'
          @search_log.search_parameter_logs << SearchParameterLog.new(name: key, value: value)
          search_terms.map! { |t| "#{t}%" }
          filter = append_boolean_expression(:ILIKE, :title, search_terms, filter)
        when 'title:contains'
          @search_log.search_parameter_logs << SearchParameterLog.new(name: key, value: value)
          search_terms.map! { |t| "%#{t}%" }
          filter = append_boolean_expression(:ILIKE, :title, search_terms, filter)
        when 'artifact-current-state'
          filter = filter.where(artifact_status: search_terms)
        when 'artifact-publisher'
          repository_ids = Repository.where { |o| { o.lower(:fhir_id) => search_terms } }.map(&:id)
          filter = filter.where(repository_id: repository_ids)
        end
      rescue StandardError
        raise InvalidParameterError.new(parameter: key, value: value)
      end
    end

    filter
  end

  def add_pagination(filter)
    @page_size = (@search_log.search_params['_count'] || -1).to_i
    @page_no = [(@search_log.search_params['page'] || 1).to_i, 1].max # the minimum value of page number is 1

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

  def self.get_fhir_datetime_range(datetime)
    range = { start: DateTime.xmlschema(datetime), end: nil }
    range[:end] =
      case datetime
      when /^\d{4}$/ # YYYY
        range[:start].next_year - 1.seconds
      when /^\d{4}-\d{2}$/ # YYYY-MM
        range[:start].next_month - 1.seconds
      when /^\d{4}-\d{2}-\d{2}$/ # YYYY-MM-DD
        range[:start].next_day - 1.seconds
      else # YYYY-MM-DDThh:mm:ss+zz:zz
        range[:start]
      end
    range
  end

  def self.parse_fhir_datetime_search(expression)
    comparator = expression[0..1]
    if %w[eq ge gt le lt ne sa eb ap].include? comparator
      expression = expression[2..]
    else
      comparator = 'eq'
    end
    get_fhir_datetime_range(expression).merge(comparator: comparator)
  end

  def self.fhir_datetime_to_postgres_search(expression)
    fhir_expr = parse_fhir_datetime_search(expression)
    case fhir_expr[:comparator]
    when 'gt', 'sa'
      ['updated_at > ?', fhir_expr[:end]]
    when 'ge'
      ['updated_at >= ?', fhir_expr[:start]]
    when 'lt', 'eb'
      ['updated_at < ?', fhir_expr[:start]]
    when 'le'
      ['updated_at <= ?', fhir_expr[:end]]
    when 'ne'
      ['updated_at < ? OR updated_at > ?', fhir_expr[:start], fhir_expr[:end]]
    else # eq, ap
      ['updated_at >= ? AND updated_at <= ?', fhir_expr[:start], fhir_expr[:end]]
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
