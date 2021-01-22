# frozen_string_literal: true

require_relative './citation'

# Service to read artifact from database and convert to FHIR resources
class FHIRAdapter
  def self.create_citation(artifact, artifact_base_url)
    remote_identifier = artifact[:remote_identifier]
    # TODO: Put handling of JSONP array into model
    # TODO: Separate different types of keywords
    keywords = JSON.parse(artifact.keywords) | JSON.parse(artifact.mesh_keywords)
    keyword_list = Citation::KeywordList.new(keyword: keywords.map { |k| Citation::KeywordList::Keyword.new(value: k) })
    Citation.new(
      id: remote_identifier,
      url: "#{artifact_base_url}/#{remote_identifier}",
      identifier: [
        {
          system: 'https://www.uspreventiveservicestaskforce.org/',
          value: get_original_identifier(remote_identifier)
        }
      ],
      title: artifact[:title],
      description: artifact[:description],
      status: 'active',
      date: artifact[:published_on],
      publisher: artifact.repository.name,
      webLocation: Citation::WebLocation.new(url: artifact[:url]),
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

  def self.get_original_identifier(remote_identifier)
    # TODO: Should update pattern with new repo adopted.
    # OR replace with original id saved in database
    remote_identifier.split('-', 3).last
  end
end
