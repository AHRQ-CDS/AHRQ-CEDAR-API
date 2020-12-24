# frozen_string_literal: true

require 'sinatra'
require 'json'

require_relative 'database/models'
require 'sinatra/namespace'
require 'fhir_models'
require 'pry'

get '/' do
  "Artifact count: #{Artifact.count}"
end

get '/:id' do |id|
  Artifact[id].to_json
end

namespace '/fhir' do
  before do
    content_type 'application/fhir+json'
  end

  get '/metadata' do
    json = File.read('resources/capabilitystatement.json')
    cs = FHIR.from_contents(json)
    return cs.to_json
  end

  get '/Citation/?:id?' do
    id = "citation-#{params[:id].nil? ? '323' : params[:id]}"
    get_resource(id)
  end

  get '/EvidenceReport/?:id?' do
    id = "evidencereport-#{params[:id].nil? ? 'cervical-cancer' : params[:id]}"
    get_resource(id)
  end

  get '/Group/?:id?' do
    id = "group-#{params[:id].nil? ? 'female-21-65' : params[:id]}"
    get_resource(id)
  end

  get '/PlanDefinition/?:id?' do
    id = "plandefinition-#{params[:id].nil? ? 'cervical-cancer' : params[:id]}"
    get_resource(id)
  end

  def get_resource(id)
    json = File.read("resources/#{id}.json")
    pd = FHIR.from_contents(json)
    pd.to_json
  end
end
