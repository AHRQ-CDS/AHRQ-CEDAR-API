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

  get '/ActivityDefinition/?:id?' do
    binding.pry
    id = params[:id].nil? ? 'activitydefinition-cervical-cancer' :params[:id] 
    get_resource(id)
  end

  get '/EvidenceReport/?:id?' do
    binding.pry
    id = params[:id].nil? ? 'evidencereport-cervical-cancer' :params[:id] 
    get_resource(id)
  end

  get '/Group/?:id?' do
    id = params[:id].nil? ? 'group-female-21-65' : params[:id] 
    get_resource(id)
  end


  def get_resource(id)
    json = File.read("resources/#{id}.json")
    pd = FHIR.from_contents(json)
    pd.to_json
  end
end
