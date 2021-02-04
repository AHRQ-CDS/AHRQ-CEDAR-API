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

  def find_resources(params)
    filter = Artifact.join(:repositories, id: :repository_id)

    params&.each do |key, value|
      case key
      when '_content'
        filter = filter.where(Sequel.ilike(:title, "%#{value}%") | Sequel.ilike(:description, "%#{value}%"))
      when 'title'
        filter = filter.where(Sequel.ilike(:title, "#{value}%"))
      when 'title:contains'
        filter = filter.where(Sequel.ilike(:title, "%#{value}%"))
      end
    end

    artifacts = filter.all
    bundle = FHIRAdapter.create_citation_bundle(artifacts, uri('fhir/Citation'))
    bundle.to_json
  end
end
