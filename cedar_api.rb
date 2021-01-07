# frozen_string_literal: true

require 'fhir_models'
require 'json'
require 'pry'
require 'sinatra'
require 'sinatra/namespace'

require_relative 'database/models'

get '/' do
  "Artifact count: #{Artifact.count}"
end

namespace '/artifact' do
  get '/:id' do |id|
    Artifact[id].to_json
  end
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
    id = params[:id].nil? ? 'citation-323' : params[:id]
    get_resource(id)
  end

  get '/EvidenceReport/?:id?' do
    id = params[:id].nil? ? 'evidencereport-cervical-cancer' : params[:id]
    get_resource(id)
  end

  get '/Group/?:id?' do
    id = "group-#{params[:id].nil? ? 'female-21-65' : params[:id]}"
    get_resource(id)
  end

  get '/PlanDefinition/?:id?' do
    id = params[:id].nil? ? 'plandefinition-cervical-cancer' : params[:id]
    get_resource(id)
  end

  def get_resource(id, use_fhir_parser: true)
    return get_resource_from_artifact(id) unless id.nil?

    json = File.read("resources/#{id}.json")
    resource = use_fhir_parser ? FHIR.from_contents(json) : JSON.parse(json)
    resource.to_json
  end

  def get_resource_from_artifact(id)
    artifact = Artifact[id]
    return nil if artifact.nil?

    artifact_type = artifact[:artifact_type]

    case artifact_type
    when 'specific_recommendation'
      create_plan_definition(artifact)
    when 'general_recommendation'
      create_general_recommendation(artifact)
    when 'tool'
      create_citation(artifact)
    end
  end

  def create_citation(artifact)
    remote_id = artifact[:remote_id]
    citation = {
      id: artifact[:id],
      identifier: [
        {
          system: 'https://www.uspreventiveservicestaskforce.org/tool',
          value: remote_id[12..]
        }
      ],
      title: artifact[:title],
      status: 'active',
      webLocation: {
        url: artifact[:url]
      }
    }

    citation.to_json
  end

  def create_general_recommendation(artifact)
    remote_id = artifact[:remote_id]

    evidence_rpt = {
      id: artifact[:id],
      identifier: [
        {
          system: 'https://www.uspreventiveservicestaskforce.org/general-recommendation',
          value: remote_id[10..]
        }
      ],
      title: artifact[:title],
      status: 'active',
      type: {
        coding: [
          {
            system: 'http://terminology.hl7.org/CodeSystem/evidence-report-type',
            code: 'text-structured'
          }
        ]
      },
      section: [
        {
          text: {
            status: 'generated',
            div: "<div xmlns=\"http://www.w3.org/1999/xhtml\">#{artifact[:description]}</div>"
          }
        }
      ]
    }

    evidence_rpt.to_json
  end

  def create_plan_definition(artifact)
    remote_id = artifact[:remote_id]

    plan_def = FHIR::PlanDefinition.new(
      id: artifact[:id],
      meta: {
        profile: [
          'http://hl7.org/fhir/uv/cpg/StructureDefinition/cpg-computableplandefinition'
        ]
      },
      text: {
        status: 'generated',
        div: "<div xmlns=\"http://www.w3.org/1999/xhtml\">#{artifact[:description]}</div>"
      },
      extension: [
        {
          url: 'http://hl7.org/fhir/uv/cpg/StructureDefinition/cpg-knowledgeCapability',
          valueCode: 'computable'
        },
        {
          url: 'http://hl7.org/fhir/uv/cpg/StructureDefinition/cpg-knowledgeRepresentationLevel',
          valueCode: 'narrative'
        },
        {
          url: 'http://hl7.org/fhir/uv/cpg/StructureDefinition/cpg-enabled',
          valueBoolean: true
        }
      ],
      url: "http://example.com/fhir/PlanDefinition/#{artifact[:id]}",
      identifier: [
        {
          system: 'https://www.uspreventiveservicestaskforce.org/specific-recommendation',
          value: remote_id[10..]
        }
      ],
      title: artifact[:title],
      type: {
        coding: [
          {
            system: 'http://terminology.hl7.org/CodeSystem/plan-definition-type',
            code: 'eca-rule',
            display: 'ECA Rule'
          }
        ]
      },
      status: 'active',
      experimental: false,
      publisher: 'USPSTF',
      description: artifact[:description],
      action: [
        {
          title: artifact[:title]
        }
      ]
    )

    plan_def.to_json
  end
end
