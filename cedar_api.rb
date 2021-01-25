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

namespace '/artifact' do
  get '/:id' do |id|
    artifact = Artifact[id]
    halt(404) if artifact.nil?
    artifact.to_json
  end
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
    find_resources(params['_content'])
  end

  def get_resource(id)
    artifact = Artifact.first(remote_identifier: id)
    halt(404) if artifact.nil?

    # TODO: Get general recommendation related to specical recommendation
    # category and keywords are saved in general recommendation
    # This should probably be done in the importer so that the API doesn't
    # need repository-specific logic

    citation = FHIRAdapter.create_citation(artifact, uri('fhir/Citation'))
    citation.to_json
  end

  def find_resources(text)
    artifacts = Artifact.where(Sequel.join(%i[title description]).ilike("%#{text}%")).all
    bundle = FHIRAdapter.create_citation_bundle(artifacts, uri('fhir/Citation'))
    bundle.to_json
  end
end
