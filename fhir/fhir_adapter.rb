# frozen_string_literal: true

require_relative './citation'

# Service to read artifact from database and convert to FHIR resources
class FHIRAdapter
  def self.create_citation(artifact, artifact_base_url)
    remote_identifier = artifact[:remote_identifier]
    Citation.new(
      id: remote_identifier,
      url: "#{artifact_base_url}/#{remote_identifier}",
      identifier: [
        {
          system: 'https://www.uspreventiveservicestaskforce.org/',
          value: original_id
        }
      ],
      title: artifact[:title],
      description: artifact[:description],
      status: 'active',
      date: artifact[:published],
      publisher: artifact.repository.name,
      webLocation: Citation::WebLocation.new(url: artifact[:url])
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
