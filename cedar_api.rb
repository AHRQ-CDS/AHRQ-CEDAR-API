# frozen_string_literal: true

require 'fhir_models'
require 'json'
require 'pry'
require 'sinatra'
require 'sinatra/namespace'

require_relative 'database/models'
require_relative 'fhir/fhir_adapter'

get '/' do
  "Artifact count: #{Artifact.count}"
end

get '/demo' do
  content_type 'text/html'
  <<~DEMO_LINKS
    <ul>
      <li><a href='/fhir/EvidenceReport/USPSTF-GR-198'>USPSTF General Recommendation - Atrial Fibrillation Screening</a></li>
      <li><a href='/fhir/PlanDefinition/USPSTF-SR-358'>USPSTF Specific Recommendation - Cervical Cancer Screening</a></li>
      <li><a href='/fhir/Citation/USPSTF-TOOL-323'>USPSTF Tool - Cervical Cancer Screening</a></li>
    </ul>
  DEMO_LINKS
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

  get '/EvidenceReport/:id' do
    id = params[:id]
    get_resource(id)
  end

  get '/PlanDefinition/:id' do
    id = params[:id]
    get_resource(id)
  end

  def get_resource(id)
    artifact = Artifact.first(remote_identifier: id)
    halt(404) if artifact.nil?

    artifact.to_fhir
  end
end
