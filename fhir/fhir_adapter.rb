# frozen_string_literal: true

require_relative './citation'

# Service to read artifact from database and convert to FHIR resources
class FHIRAdapter
  def self.create_citation(artifact, artifact_base_url)
    cedar_identifier = artifact[:cedar_identifier]
    # TODO: Put handling of JSONP array into model
    # TODO: Separate different types of keywords
    keywords = JSON.parse(artifact.keywords) | JSON.parse(artifact.mesh_keywords)
    keyword_list = Citation::KeywordList.new(keyword: keywords.map { |k| Citation::KeywordList::Keyword.new(value: k) })
    Citation.new(
      id: cedar_identifier,
      url: "#{artifact_base_url}/#{cedar_identifier}",
      identifier: [
        {
          system: 'http://ahrq.gov/cedar',
          value: cedar_identifier
        },
        {
          system: artifact.repository.home_page,
          value: artifact.remote_identifier
        }
      ],
      title: artifact.title,
      description: artifact.description,
      status: artifact.artifact_status,
      date: artifact.published_on,
      publisher: artifact.repository.name,
      webLocation: Citation::WebLocation.new(url: artifact.url),
      keywordList: keyword_list
    )
  end

  def self.create_citation_bundle(artifacts, artifact_base_url)
    bundle = FHIR::Bundle.new(
      type: 'searchset'
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
