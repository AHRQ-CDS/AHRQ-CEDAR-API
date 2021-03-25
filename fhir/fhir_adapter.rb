# frozen_string_literal: true

require_relative './citation'

# Service to read artifact from database and convert to FHIR resources
class FHIRAdapter
  def self.create_citation(artifact, artifact_base_url)
    cedar_identifier = artifact[:cedar_identifier]
    # TODO: Put handling of JSONP array into model
    # TODO: Separate different types of keywords
    keywords = JSON.parse(artifact.keywords)
    keyword_list = keywords.map { |k| FHIR::CodeableConcept.new(text: k) }
    mesh_keywords = JSON.parse(artifact.mesh_keywords)
    mesh_keyword_list = mesh_keywords.map { |k| FHIR::CodeableConcept.new(text: k) }

    citation = FHIR::Citation.new(
      id: cedar_identifier,
      url: "#{artifact_base_url}/#{cedar_identifier}",
      identifier: [
        {
          system: 'http://ahrq.gov/cedar',
          value: cedar_identifier
        }
      ],
      title: artifact.title,
      status: 'active', # Will a CEDAR citation be retired in the future?
      date: to_fhir_date(artifact.updated_at),
      publisher: 'CEDAR',
      # classification: Does CEDAR citation have its own keywords?
      # copyright: need CEDAR copyright declaration here
      citedArtifact: {
        identifier: [
          {
            system: artifact.repository.home_page,
            value: artifact.remote_identifier
          }
        ],
        dateAccessed: to_fhir_date(artifact.updated_at),
        currentState: [
          {
            coding: {
              system: 'http://hl7.org/fhir/publication-status',
              code: artifact.artifact_status
            }
          }
        ],
        title: [
          {
            text: artifact.title
          }
        ],
        abstract: [
          {
            text: artifact.description_markdown
          }
        ],
        # copyright: Need repo's copyright declaration here
        publicationForm: {
          publishedIn: {
            publisher: {
              display: artifact.repository.name
            }
          },
          articleDate: to_fhir_date(artifact.published_on)
        },
        webLocation: [
          {
            url: artifact.url
          }
        ]
      }
    )

    unless artifact.description_html.nil?
      citation.text = FHIR::Narrative.new(
        status: 'generated',
        div: "<div xmlns=\"http://www.w3.org/1999/xhtml\">#{artifact.description_html}</div>"
      )
    end

    if keyword_list.any?
      citation.citedArtifact.classification << FHIR::Citation::CitedArtifact::Classification.new(
        type: {
          coding: [
            {
              system: 'http://terminology.hl7.org/CodeSystem/cited-artifact-classification-type',
              code: 'keyword'
            }
          ]
        },
        classifier: keyword_list
      )
    end

    if mesh_keyword_list.any?
      citation.citedArtifact.classification << FHIR::Citation::CitedArtifact::Classification.new(
        type: {
          coding: [
            {
              system: 'http://terminology.hl7.org/CodeSystem/cited-artifact-classification-type',
              code: 'mesh-heading'
            }
          ]
        },
        classifier: mesh_keyword_list
      )
    end

    citation
  end

  def self.to_fhir_date(timestamp)
    timestamp&.strftime('%F')
  end

  def self.create_citation_bundle(artifacts, artifact_base_url)
    bundle = FHIR::Bundle.new(
      type: 'searchset',
      total: artifacts.size
    )
    artifacts.each do |artifact|
      citation = create_citation(artifact, artifact_base_url)
      entry = FHIR::Bundle::Entry.new(
        resource: citation
      )
      bundle.entry << entry
    end
    bundle
  end
end
