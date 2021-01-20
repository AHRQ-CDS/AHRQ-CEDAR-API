# frozen_string_literal: true

require_relative '../database/models'

# Service to read artifact from database and convert to FHIR resources
class FHIRAdapter
  def get_resource(id)
    return nil if id.nil?

    artifact = Artifact.first(remote_identifier: id)
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
    remote_identifier = artifact[:remote_identifier]
    citation = {
      resourceType: 'Citation',
      id: remote_identifier,
      identifier: [
        {
          system: 'https://www.uspreventiveservicestaskforce.org/tool',
          value: remote_identifier
        }
      ],
      title: artifact[:title],
      status: 'active',
      webLocation: {
        url: artifact[:url]
      }
    }

    JSON.pretty_generate(citation)
  end

  def create_general_recommendation(artifact)
    remote_identifier = artifact[:remote_identifier]

    evidence_rpt = {
      resourceType: 'EvidenceReport',
      id: remote_identifier,
      identifier: [
        {
          system: 'https://www.uspreventiveservicestaskforce.org/general-recommendation',
          value: remote_identifier
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
      relatedArtifact: {
        type: 'documentation',
        url: artifact[:url]
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

    JSON.pretty_generate(evidence_rpt)
  end

  def create_plan_definition(artifact)
    remote_identifier = artifact[:remote_identifier]

    plan_def = FHIR::PlanDefinition.new(
      id: remote_identifier,
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
      url: "http://example.com/fhir/PlanDefinition/#{artifact[:remote_identifier]}",
      identifier: [
        {
          system: 'https://www.uspreventiveservicestaskforce.org/specific-recommendation',
          value: remote_identifier
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
      ],
      relatedArtifact: {
        type: 'documentation',
        url: artifact[:url]
      }
    )

    plan_def.to_json
  end
end
