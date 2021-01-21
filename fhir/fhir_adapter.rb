# frozen_string_literal: true

# Service to read artifact from database and convert to FHIR resources
class FHIRAdapter
  def self.parse_to_fhir(artifact)
    create_citation(artifact)
  end

  def self.create_citation(artifact)
    remote_identifier = artifact[:remote_identifier]
    original_id = get_original_identifier(remote_identifier)
    citation = {
      resourceType: 'Citation',
      id: remote_identifier,
      identifier: [
        {
          system: 'https://www.uspreventiveservicestaskforce.org/',
          value: original_id
        }
      ],
      title: artifact[:title],
      description: artifact[:description],
      status: 'active',
      publisher: 'USPSTF',
      webLocation: {
        url: artifact[:url]
      }
    }

    JSON.pretty_generate(citation)
  end

  def self.create_general_recommendation(artifact)
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

  def self.create_plan_definition(artifact)
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

  def self.get_original_identifier(remote_identifier)
    # TODO: Should update pattern with new repo adopted.
    # OR replace with original id saved in database
    substr = remote_identifier.split('-', 3)
    substr[2]
  end
end
