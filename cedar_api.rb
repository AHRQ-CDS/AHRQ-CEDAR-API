# frozen_string_literal: true

require 'fhir_models'
require 'json'
require 'pry'
require 'sinatra'
require 'sinatra/namespace'
require 'sinatra/cross_origin'

require_relative 'database/models'
require_relative 'fhir/fhir_adapter'
require_relative 'util/api_helper'
require_relative 'util/search_parser'

configure do
  # Support cross-origin requests to allow JavaScript-based UIs hosted on different servers
  enable :cross_origin
end

get '/' do
  "Artifact count: #{Artifact.count}"
end

get '/demo' do
  content_type 'text/html'
  <<~DEMO_FORM
    <form action="/fhir/Citation" method="get">
      <label for="_content">Search Text:</label>
      <input type="text" id="_content" name="_content">
      <input type="hidden" id="artifact-current-state" name="artifact-current-state" value="active">
      <button type="submit">Search</button>
    </form>
    <form action="/fhir/Citation" method="get">
      <label for="keyword">Search Keywords:</label>
      <input type="text" id="classification" name="classification">
      <input type="hidden" id="artifact-current-state" name="artifact-current-state" value="active">
      <button type="submit">Search</button>
    </form>
    <form action="/fhir/Citation" method="get">
      <label for="title">Search Title:</label>
      <input type="text" id="title" name="title:contains">
      <input type="hidden" id="artifact-current-state" name="artifact-current-state" value="active">
      <button type="submit">Search</button>
    </form>
    <ul>
  DEMO_FORM
end

not_found do
  'Not found'
end

namespace '/fhir' do
  before do
    content_type 'application/fhir+json; charset=utf-8'
    response.headers['Access-Control-Allow-Origin'] = '*'
  end

  get '/metadata' do
    json = File.read('resources/capabilitystatement.json')
    cs = FHIR.from_contents(json)
    return cs.to_json
  end

  get '/SearchParameter' do
    case params['url']
    when /cedar-citiation-classification/
      return FHIR.from_contents(File.read('resources/searchparameter-classification.json')).to_json
    when /cedar-citiation-title/
      return FHIR.from_contents(File.read('resources/searchparameter-title.json')).to_json
    else
      halt(404)
    end
  end

  get '/Organization' do
    bundle = FHIRAdapter.create_organization_bundle(Repository.all)

    uri = Addressable::URI.parse("#{request.scheme}://#{request.host}:#{request.port}#{request.path}")

    # add link if request is not count only
    bundle.link << FHIR::Bundle::Link.new(
      {
        relation: 'self',
        url: uri.normalize.to_str
      }
    )

    bundle.to_json
  end

  get '/Organization/:id' do
    id = params[:id]

    repo = Repository.first(fhir_id: id)
    halt(404) if repo.nil?

    citation = FHIRAdapter.create_organization(repo)
    citation.to_json
  end

  get '/Citation/:id' do
    id = params[:id]

    artifact = Artifact.first(cedar_identifier: id)
    halt(404) if artifact.nil?

    citation = FHIRAdapter.create_citation(artifact, uri('fhir/Citation'))
    citation.to_json
  end

  get '/Citation' do
    find_citation(params)
  end

  def find_citation(params)
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

      return oo.to_json
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
    if page_size.zero?
      bundle = FHIRAdapter.create_citation_bundle(nil, uri('fhir/Citation'), filter.count, true)
      return bundle.to_json
    end

    # if page size is greater than 0, return paginated results.
    # otherwise, return all results
    if page_size.positive?
      artifacts = filter.paginate(page_no, page_size)
      total = artifacts.pagination_record_count
    else
      artifacts = filter.all
      total = artifacts.size
    end

    bundle = FHIRAdapter.create_citation_bundle(artifacts, uri('fhir/Citation'), total, page_size.zero?)

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

    bundle.to_json
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
