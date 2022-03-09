# frozen_string_literal: true

require 'addressable'
require 'time'
require 'date'
require 'active_support/core_ext/numeric/time'
require 'sinatra'

require_relative '../database/models'
require_relative '../fhir/fhir_adapter'
require_relative 'errors'
require_relative 'cedar_logger'

# Helper methods for CEDAR API
class CitationFilter
  UMLS_CODE_SYSTEM_IDS = FHIRAdapter::FHIR_CODE_SYSTEM_URLS.invert.freeze
  MULTIPLE_AND_PARAMETERS = ['classification'].freeze
  STATUS_SORT_ORDER = { 'active' => 1, 'draft' => 2, 'unknown' => 3, 'archived' => 4, 'retracted' => 5 }.freeze

  def initialize(params:, base_url:, request_url:, client_ip: nil, log_to_db: false)
    @artifact_base_url = base_url
    @request_url = request_url
    @client_ip = client_ip
    @log_to_db = log_to_db
    @search_params = params
    @search_parameter_logs = []
    @client_ip = client_ip
  end

  def build_link_url(page_no, page_size)
    uri = Addressable::URI.parse(@request_url)
    new_params = @search_params.reject { |key, _value| %w[_count page].include?(key) }

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
                 Concept.where(synonyms_op.contains([{ code: code }])).or(umls_cui: code)
               elsif UMLS_CODE_SYSTEM_IDS[system] == 'MTH'
                 Concept.where(umls_cui: code)
               else
                 Concept.where(synonyms_op.contains([{ system: UMLS_CODE_SYSTEM_IDS[system], code: code }]))
               end
    concepts.map { |c| c.artifacts.collect(&:id) }.flatten.uniq
  end

  def citations
    search_log = SearchLog.new(search_params: @search_params, client_ip: @client_ip, start_time: Time.now.utc)

    # Create the filter then add the default ordering after whatever primary ordering (e.g. rank for free text)
    # is present
    filter = build_filter.order_append(Sequel.case(STATUS_SORT_ORDER, 5, :artifact_status))
                         .order_append(Sequel.desc(:published_on))
                         .order_append(Sequel.desc(:strength_of_recommendation_sort))
                         .order_append(Sequel.desc(:quality_of_evidence_sort))

    begin
      paged_result = add_pagination(filter)
    rescue StandardError => e
      CedarLogger.error "Failed to add search pagination: #{e.full_message}"
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
      search_log.count = artifacts.count unless @page_size.zero?
      search_log.total = total
      search_log.end_time = Time.now.utc

      begin
        search_log.save_changes
        @search_parameter_logs.each do |search_parameter_log|
          search_log.add_search_parameter_log(search_parameter_log)
        end
      rescue StandardError => e
        CedarLogger.error "Failed to log search: #{e.full_message}"
        # We should continue the workflow if logging failed.
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

    @search_params&.each do |key, value|
      search_terms = value.split(',').map { |v| v.strip.downcase.to_s } if value.is_a?(String)

      begin
        case key
        when '_content'
          @search_parameter_logs << SearchParameterLog.new(name: key, value: value)

          cols = SearchParser.parse(value)
          opt = {
            language: 'english',
            rank: true,
            tsvector: true
          }

          filter = filter.full_text_search(:content_search, cols, opt)
        when '_lastUpdated'
          postgres_search_terms = self.class.fhir_datetime_to_postgres_search(value, 'updated_at')
          filter = filter.where(Sequel.lit(*postgres_search_terms))
        when 'article-date'
          postgres_search_terms = self.class.fhir_datetime_to_postgres_search(value, 'published_on')
          filter = filter.where(Sequel.lit(*postgres_search_terms))
        when 'article-date:missing'
          filter = filter.where(published_on: nil) if value
        when 'classification'
          @search_parameter_logs << SearchParameterLog.new(name: key, value: value)

          # All matching artifacts for each concept, structure is three level nested array.
          # E.g. classification=A,B&classification=C would yield the following
          # [
          #   [
          #     [ artifact ids for concept A],
          #     [ artifact ids for concept B]
          #   ],
          #   [
          #     [ artifact ids for concept C],
          #   ]
          # ]
          artifact_id_list = Array(value).map do |terms|
            terms.split(',').map { |term| get_artifacts_with_concept(term) }
          end

          # distinct list of matching artifacts after applying ORs and ANDs between sets
          distinct_ids = artifact_id_list.map do |ored_terms|
            ored_terms.inject(:|) # OR for comma separated terms
          end.inject(:&) # AND for terms from separate arguments

          # Count how often each artifact id is present, a higher count means that artifact matched more concepts
          id_frequency_counts = artifact_id_list.flatten.each_with_object({}) do |item, hsh|
            hsh[item] = hsh[item].to_i + 1 # to_i since initial value will be nil
          end

          filter = filter.where(Sequel[:artifacts][:id] => distinct_ids)
                         .order_append(Sequel.desc(Sequel.case(id_frequency_counts, 0, :id)))
        when 'classification:text'
          @search_parameter_logs << SearchParameterLog.new(name: key, value: value)
          cols = SearchParser.parse(value)
          opt = {
            language: 'english',
            rank: true
          }

          # Need to decide if we need use ts_vector to get better performance
          filter = filter.full_text_search(:keyword_text, cols, opt)
        when 'title'
          @search_parameter_logs << SearchParameterLog.new(name: key, value: value)
          search_terms.map! { |t| "#{t}%" }
          filter = append_boolean_expression(:ILIKE, :title, search_terms, filter)
        when 'title:contains'
          @search_parameter_logs << SearchParameterLog.new(name: key, value: value)
          search_terms.map! { |t| "%#{t}%" }
          filter = append_boolean_expression(:ILIKE, :title, search_terms, filter)
        when 'artifact-current-state'
          filter = filter.where(artifact_status: search_terms)
        when 'artifact-publisher'
          repository_ids = Repository.where { |o| { o.lower(:fhir_id) => search_terms } }.map(&:id)
          filter = filter.where(repository_id: repository_ids)
        when 'artifact-type'
          filter = filter.where(Sequel.lit('LOWER(artifact_type) IN ?', search_terms))
        end
      rescue StandardError => e
        CedarLogger.error "Failed to add filter: #{e.full_message}"
        raise InvalidParameterError.new(parameter: key, value: value)
      end
    end

    filter
  end

  def add_pagination(filter)
    @page_size = (@search_params['_count'] || -1).to_i
    @page_no = [(@search_params['page'] || 1).to_i, 1].max # the minimum value of page number is 1

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

  def self.fhir_datetime_to_postgres_search(expression, column)
    # Because column is passed in and is used directly in a SQL statement in a way that could allow SQL
    # injection if it were user specified we take extra care to ensure that it's one of two valid values
    raise "Invalid datetime column name specified (#{column})" unless %w[updated_at published_on].include?(column)

    fhir_expr = parse_fhir_datetime_search(expression)
    case fhir_expr[:comparator]
    when 'gt', 'sa'
      ["#{column} > ?", fhir_expr[:end]]
    when 'ge'
      ["#{column} >= ?", fhir_expr[:start]]
    when 'lt', 'eb'
      ["#{column} < ?", fhir_expr[:start]]
    when 'le'
      ["#{column} <= ?", fhir_expr[:end]]
    when 'ne'
      ["#{column} < ? OR #{column} > ?", fhir_expr[:start], fhir_expr[:end]]
    else # eq, ap
      ["#{column} >= ? AND #{column} <= ?", fhir_expr[:start], fhir_expr[:end]]
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
