# frozen_string_literal: true

require 'fhir_models'
require 'json'
require 'pry'
require 'sinatra'
require 'sinatra/namespace'
require 'sinatra/cross_origin'

require_relative 'database/models'
require_relative 'fhir/fhir_adapter'

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
    filename = nil
    params&.each do |key, value|
      if key == 'url'
        case value
        when 'http://ahrq.gov/cedar/SearchParameter/cedar-citiation-classification'
          filename = 'classification'
        when 'http://ahrq.gov/cedar/SearchParameter/cedar-citiation-title'
          filename = 'title'
        end
        break
      end
    end

    if filename.nil?
      halt(404)
    else
      json = File.read("resources/searchparameter-#{filename}.json")
      cs = FHIR.from_contents(json)
      return cs.to_json
    end
  end

  get '/Citation/:id' do
    id = params[:id]
    get_resource(id)
  end

  get '/Citation' do
    find_resources(params)
  end

  def get_resource(id)
    artifact = Artifact.first(cedar_identifier: id)
    halt(404) if artifact.nil?

    citation = FHIRAdapter.create_citation(artifact, uri('fhir/Citation'))
    citation.to_json
  end

  def parse_full_text_search(term)
    # TODO: Need a better way to handle: A AND (B OR (NOT C))
    term.gsub('AND', '&').to_s.gsub('OR', '|').to_s.gsub('NOT', '!').to_s
  end

  def find_resources(params)
    filter = Artifact.join(:repositories, id: :repository_id)

    params&.each do |key, value|
      search_terms = value.split(',').map { |v| v.strip.downcase.to_s }

      case key
      when '_content'
        cols = parse_full_text_search(value)
        opt = {
          language: 'english',
          rank: true,
          tsvector: true
        }

        filter = filter.full_text_search(:content_search, cols, opt)
      when 'classification'
        cols = parse_full_text_search(value)
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
      end
    end

    artifacts = filter.all
    bundle = FHIRAdapter.create_citation_bundle(artifacts, uri('fhir/Citation'))
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

  def append_placeholder_string(str, search_terms, filter)
    if search_terms.length == 1
      filter = filter.where(Sequel::SQL::PlaceholderLiteralString.new(str, search_terms.first))
    elsif search_terms.length > 1
      args = search_terms.map { |term| Sequel::SQL::PlaceholderLiteralString.new(str, term) }
      filter = filter.where(Sequel::SQL::BooleanExpression.new(:OR, *args))
    end

    filter
  end
end
