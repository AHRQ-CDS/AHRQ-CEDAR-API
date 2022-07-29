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
  MULTIPLE_AND_PARAMETERS = ['classification', 'title:contains'].freeze
  STATUS_SORT_ORDER = { 'active' => 1, 'draft' => 2, 'unknown' => 3, 'archived' => 4, 'retracted' => 5 }.freeze
  FHIR_DB_FIELD = {
    '_score' => :id,
    'artifact-current-state' => :artifact_status,
    'article-date' => :published_on,
    'strength-of-recommendation' => :strength_of_recommendation_sort,
    'quality-of-evidence' => :quality_of_evidence_sort
  }.freeze
  DEFAULT_SORT_ORDER = [
    { field: '_score', order: :desc },
    { field: 'artifact-current-state', order: :asc },
    { field: 'article-date', order: :desc },
    { field: 'strength-of-recommendation', order: :desc },
    { field: 'quality-of-evidence', order: :desc }
  ].freeze
  CERTAINTY_VALUES = FHIRAdapter::QUALITY_OF_EVIDENCE_CODES.to_h { |entry| [entry[:code], entry[:sort_value]] }.freeze
  DEFAULT_PAGE_SIZE = 10

  def initialize(params:, artifact_base_url:, redirect_base_url:, request_url:, client_ip: nil, log_to_db: false)
    @search_params = params
    @artifact_base_url = artifact_base_url
    @redirect_base_url = redirect_base_url
    @request_url = request_url
    @client_ip = client_ip
    @log_to_db = log_to_db
    @sort_order = DEFAULT_SORT_ORDER
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

  def init_search_log
    SearchLog.create(search_params: @search_params, client_ip: @client_ip, start_time: Time.now.utc) if @log_to_db
  end

  def finalize_search_log(search_log, all_results, paged_results)
    if @log_to_db
      repository_result_counts = {}
      count_results_by_repository(repository_result_counts, :total, all_results)
      count_results_by_repository(repository_result_counts, :count, paged_results) unless paged_results.nil?
      repository_result_counts.each_pair do |repository_id, result_counts|
        result_counts[:alias] = Repository[repository_id].alias
      end

      search_log.total = all_results.count
      search_log.count = paged_results.count unless paged_results.nil?
      search_log.end_time = Time.now.utc
      search_log.repository_results = repository_result_counts

      begin
        search_log.save_changes
      rescue StandardError => e
        CedarLogger.error "Failed to log search: #{e.full_message}"
        # We should continue the workflow if logging failed.
      end
    end
  end

  def all_artifacts
    search_log = init_search_log
    filter = build_filter
    artifacts = filter.all
    finalize_search_log(search_log, artifacts, artifacts)
    artifacts
  end

  def citations
    search_log = init_search_log
    filter = build_filter
    artifacts = filter.all

    begin
      paged_result = add_pagination(filter)
    rescue StandardError => e
      CedarLogger.error "Failed to add search pagination: #{e.full_message}"
      raise DatabaseError.new(message: e.message)
    end

    bundle = if @page_size.zero?
               # if _count=0, return count only
               FHIRAdapter.create_citation_bundle(total: paged_result[:total])
             else
               FHIRAdapter.create_citation_bundle(total: paged_result[:total],
                                                  artifacts: paged_result[:artifacts],
                                                  artifact_base_url: @artifact_base_url,
                                                  redirect_base_url: @redirect_base_url,
                                                  offset: @page_size * (@page_no - 1),
                                                  search_id: search_log&.id.to_i)
             end

    add_bundle_links(bundle, paged_result[:artifacts])
    finalize_search_log(search_log, artifacts, paged_result[:artifacts])
    bundle
  end

  def count_results_by_repository(result, prop, artifacts)
    artifacts.each do |artifact|
      result[artifact.repository_id] ||= {}
      result[artifact.repository_id][prop] ||= 0
      result[artifact.repository_id][prop] += 1
    end
  end

  def build_filter
    # Don't join other tables here since:
    # 1. Their id columns override the artifact id and that causes problems using the Sequel models
    #    that rely on id joins
    # 2. The many-to-many relationship with concepts results in multiple rows per artifact
    filter = Artifact.dataset
    id_frequency_counts = nil

    @search_params&.each do |key, value|
      search_terms = value.split(',').map { |v| v.strip.downcase.to_s } if value.is_a?(String)

      begin
        case key
        when '_content'
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
          postgres_search_terms = self.class.fhir_datetime_to_postgres_range_search(value, 'published_on')
          filter = filter.where(Sequel.lit(*postgres_search_terms))
        when 'article-date:missing'
          filter = if value.to_s.downcase == 'true'
                     filter.where(published_on: nil)
                   else
                     filter.exclude(published_on: nil)
                   end
        when 'classification'
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

          filter = filter.where(Sequel[:artifacts][:id] => distinct_ids)

          unless artifact_id_list.nil? || artifact_id_list.flatten.blank?
            # Count how often each artifact id is present, a higher count means that artifact matched more concepts
            # May be used later if sorting by _score is specified
            id_frequency_counts = artifact_id_list.flatten.tally
          end
        when 'classification:text'
          cols = SearchParser.parse(value)
          opt = {
            language: 'english',
            rank: true
          }

          # Need to decide if we need use ts_vector to get better performance
          filter = filter.full_text_search(:keyword_text, cols, opt)
        when 'title'
          search_terms.map! { |t| "#{t}%" }
          filter = append_boolean_expression(:ILIKE, :title, search_terms, filter)
        when 'title:contains'
          search_terms = [value].flatten.map { |s| s.split(',').map { |v| "%#{v.strip}%" } }
          # search_terms is an array of arrays. Top level items are ANDed together and second level
          # items are ORed
          # e.g. a query string containing title:contains=foo,bar&title:contains=baz would result in:
          # [["%foo%", "%bar%"], ["%baz%"]] which in SQL would be
          # WHERE (title ILIKE '%foo%' OR title ILIKE '%bar%') AND (title ILIKE '%baz%')
          search_terms.each do |ored_terms|
            filter = append_boolean_expression(:ILIKE, :title, ored_terms, filter)
          end
        when 'artifact-current-state'
          filter = filter.where(artifact_status: search_terms)
        when 'artifact-publisher'
          repository_ids = Repository.where { |o| { o.lower(:fhir_id) => search_terms } }.map(&:id)
          filter = filter.where(repository_id: repository_ids)
        when 'artifact-type'
          filter = filter.where(Sequel.lit('LOWER(artifact_type) IN ?', search_terms))
        when 'strength-of-recommendation'
          certainty_values = search_terms.map { |code| CERTAINTY_VALUES[code] }.compact
          filter = filter.where(strength_of_recommendation_sort: certainty_values)
        when 'strength-of-recommendation:missing'
          filter = if value.to_s.downcase == 'true'
                     filter.where(strength_of_recommendation_score: nil)
                           .where(strength_of_recommendation_statement: nil)
                   else
                     filter.where do
                       (Sequel.~(strength_of_recommendation_score: nil)) |
                         (Sequel.~(strength_of_recommendation_statement: nil))
                     end
                   end
        when 'quality-of-evidence'
          certainty_values = search_terms.map { |code| CERTAINTY_VALUES[code] }.compact
          filter = filter.where(quality_of_evidence_sort: certainty_values)
        when 'quality-of-evidence:missing'
          filter = if value.to_s.downcase == 'true'
                     filter.where(quality_of_evidence_score: nil)
                           .where(quality_of_evidence_statement: nil)
                   else
                     filter.where do
                       (Sequel.~(quality_of_evidence_score: nil)) |
                         (Sequel.~(quality_of_evidence_statement: nil))
                     end
                   end
        when '_sort'
          @sort_order = search_terms.map do |term|
            if term.start_with?('-')
              order = :desc
              term = term[1..]
            else
              order = :asc
            end
            raise "Unsupported sort field #{term}" if FHIR_DB_FIELD[term].nil?

            { field: term, order: order }
          end
        end
      rescue StandardError => e
        CedarLogger.error "Failed to process search parameter: #{e.full_message}"
        raise InvalidParameterError.new(parameter: key, value: value)
      end
    end

    # Add the sort ordering
    # This is slightly complicated by the use of free_text_search above where the order by search rank
    # is pre-appended. To address this, we loop from the position of the _score sort criteria
    # (corresponding to search rank) down and prepend those orderings then append any sort criteria that follow.
    score_position = @sort_order.index { |entry| entry[:field] == '_score' }
    score_position = @sort_order.size if score_position.nil?
    @sort_order[..score_position].reverse.map { |e| to_sort_order(e, id_frequency_counts) }.each do |sort_entry|
      filter = filter.order_prepend(sort_entry) unless sort_entry.nil?
    end
    @sort_order[score_position + 1..]&.map { |e| to_sort_order(e, id_frequency_counts) }&.each do |sort_entry|
      filter = filter.order_append(sort_entry) unless sort_entry.nil?
    end

    filter
  end

  def to_sort_order(sort_entry, id_frequency_counts)
    case sort_entry[:field]
    when '_score'
      if id_frequency_counts
        Sequel.send(sort_entry[:order], Sequel.case(id_frequency_counts, 0, FHIR_DB_FIELD[sort_entry[:field]]))
      end
    when 'artifact-current-state'
      Sequel.send(sort_entry[:order], Sequel.case(STATUS_SORT_ORDER, 5, FHIR_DB_FIELD[sort_entry[:field]]))
    else
      Sequel.send(sort_entry[:order], FHIR_DB_FIELD[sort_entry[:field]])
    end
  end

  def add_pagination(filter)
    @page_size = (@search_params['_count'] || DEFAULT_PAGE_SIZE).to_i
    @page_no = [(@search_params['page'] || 1).to_i, 1].max # the minimum value of page number is 1

    if @page_size.positive?
      # if page size is greater than 0, return paginated results.
      artifacts = filter.paginate(@page_no, @page_size)
      total = artifacts.pagination_record_count
    else
      # if page size is 0, return the count only
      artifacts = nil
      total = filter.count
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
    # injection if it were user specified we take extra care to ensure that it's a valid value
    raise "Invalid datetime column name specified (#{column})" unless %w[updated_at].include?(column)

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

  def self.fhir_datetime_to_postgres_range_search(expression, column)
    # Because column is passed in and is used directly in a SQL statement in a way that could allow SQL
    # injection if it were user specified we take extra care to ensure that it's a valid value
    raise "Invalid datetime column name specified (#{column})" unless %w[published_on].include?(column)

    fhir_expr = parse_fhir_datetime_search(expression)
    case fhir_expr[:comparator]
    when 'gt'
      ["#{column}_end > ?", fhir_expr[:end]]
    when 'sa'
      ["#{column}_start > ?", fhir_expr[:end]]
    when 'ge'
      ["#{column}_end > ? OR #{column}_start >= ?", fhir_expr[:start], fhir_expr[:end]]
    when 'lt'
      ["#{column}_start < ?", fhir_expr[:start]]
    when 'eb'
      ["#{column}_end < ?", fhir_expr[:start]]
    when 'le'
      ["#{column}_start < ? OR #{column}_end <= ?", fhir_expr[:start], fhir_expr[:end]]
    when 'ne'
      ["#{column}_start < ? OR #{column}_end > ?", fhir_expr[:start], fhir_expr[:end]]
    else # eq, ap
      ["#{column}_start >= ? AND #{column}_end <= ?", fhir_expr[:start], fhir_expr[:end]]
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
