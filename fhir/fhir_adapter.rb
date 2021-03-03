# frozen_string_literal: true

require_relative './citation'

# Service to read artifact from database and convert to FHIR resources
class FHIRAdapter
  def self.create_citation(artifact, artifact_base_url)
    cedar_identifier = artifact[:cedar_identifier]
    # TODO: Put handling of JSONP array into model
    # TODO: Separate different types of keywords
    keywords = JSON.parse(artifact.keywords) | JSON.parse(artifact.mesh_keywords)
    keyword_list = FHIR::Citation::KeywordList.new(
      keyword: keywords.map { |k| FHIR::Citation::KeywordList::Keyword.new(value: k) }
    )

    citation = FHIR::Citation.new(
      id: cedar_identifier,
      url: "#{artifact_base_url}/#{cedar_identifier}",
      identifier: [
        {
          system: 'http://ahrq.gov/cedar',
          value: cedar_identifier
        }
      ],
      extension: [
        {
          url: 'http://http://ahrq.gov/cedar/StructureDefinition/cedar-artifact-status',
          valueCodeableConcept: {
            coding: [
              system: 'http://hl7.org/fhir/publication-status',
              code: artifact.artifact_status
            ]
          }
        }
      ],
      status: 'active',
      title: artifact.title,
      articleTitle: {
        text: artifact.title
      },
      description: artifact.description_markdown,
      date: artifact.published_on,
      publisher: artifact.repository.name,
      webLocation: FHIR::Citation::WebLocation.new(url: artifact.url),
      keywordList: keyword_list,
      publicationForm: {
        publishingModel: {
          coding: [
            {
              system: 'http://terminology.hl7.org/CodeSystem/publishing-model-type',
              code: 'Electronic'
            }
          ]
        },
        publishedIn: {
          type: {
            coding: [
              {
                system: 'http://terminology.hl7.org/CodeSystem/published-in-type',
                code: 'D019991',
                display: 'Database'
              }
            ]
          }
        },
        title: artifact.repository.name
      }
    )

    unless artifact.remote_identifier.nil?
      citation.extension << FHIR::Extension.new(
        url: 'http://ahrq.gov/cedar/StructureDefinition/cedar-artifact-identifier',
        valueIdentifier: {
          system: artifact.repository.home_page,
          value: artifact.remote_identifier
        }
      )
    end

    unless artifact.description_html.nil?
      citation.text = FHIR::Narrative.new(
        status: 'generated',
        div: "<div xmlns=\"http://www.w3.org/1999/xhtml\">#{artifact.description_html}</div>"
      )
    end

    citation
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
