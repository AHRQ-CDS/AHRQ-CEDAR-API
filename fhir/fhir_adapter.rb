# frozen_string_literal: true

require_relative './citation'

# Service to read artifact from database and convert to FHIR resources
class FHIRAdapter
  FHIR_CODE_SYSTEM_URLS = {
    'MSH' => 'https://www.nlm.nih.gov/mesh/',
    'MEDLINEPLUS' => 'http://www.nlm.nih.gov/research/umls/medlineplus',
    'SNOMEDCT_US' => 'http://snomed.info/sct',
    'SCTSPA' => 'http://snomed.info/sct/449081005',
    'MSHSPA' => 'http://www.nlm.nih.gov/research/umls/mshspa',
    'ICD10CM' => 'http://hl7.org/fhir/sid/icd-10-cm',
    'RXNORM' => 'http://www.nlm.nih.gov/research/umls/rxnorm'
  }.freeze

  HOSTNAME = ENV['HOSTNAME'] || 'http://cedar.arhq.gov'

  def self.create_citation(artifact, artifact_base_url)
    cedar_identifier = artifact[:cedar_identifier]
    # TODO: Put handling of JSONP array into model
    # TODO: Separate different types of keywords
    keywords = artifact.keywords
    keyword_list = keywords.map { |k| FHIR::CodeableConcept.new(text: k) }
    umls_concepts = artifact.concepts
    umls_concept_list = umls_concepts.map do |concept|
      codes = concept.codes.map do |c|
        {
          system: FHIR_CODE_SYSTEM_URLS[c['system']],
          code: c['code'],
          display: c['description']
        }
      end
      FHIR::CodeableConcept.new(text: concept.umls_description, coding: codes)
    end

    citation = FHIR::Citation.new(
      id: cedar_identifier,
      url: "#{artifact_base_url}/#{cedar_identifier}",
      identifier: [
        {
          system: HOSTNAME,
          value: cedar_identifier
        }
      ],
      title: artifact.title,
      status: 'active', # Will a CEDAR citation be retired in the future?
      date: to_fhir_date(artifact.updated_at),
      publisher: 'CEDAR',
      contact: [
        {
          name: 'CEDAR',
          telecom: {
            system: 'url',
            value: HOSTNAME,
            use: 'work'
          }
        }
      ],
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
            text: artifact.title,
            type: {
              coding: [
                {
                  system: 'http://terminology.hl7.org/CodeSystem/title-type',
                  code: 'primary-human-use',
                  display: 'Primary human use'
                }
              ]
            },
            language: {
              coding: [
                {
                  system: 'urn:ietf:bcp:47',
                  code: 'en-US',
                  display: 'English (United States)'
                }
              ]
            }
          }
        ],
        abstract: [
          {
            text: artifact.description_markdown || artifact.description,
            type: {
              coding: [
                {
                  system: 'http://terminology.hl7.org/CodeSystem/cited-artifact-abstract-type',
                  code: 'primary-human-use',
                  display: 'Primary human use'
                }
              ]
            },
            language: {
              coding: [
                {
                  system: 'urn:ietf:bcp:47',
                  code: 'en-US',
                  display: 'English (United States)'
                }
              ]
            }
          }
        ],
        # copyright: Need repo's copyright declaration here
        publicationForm: [
          {
            publishedIn: {
              publisher: {
                reference: "Organization/#{artifact.repository.fhir_id}",
                display: artifact.repository.name
              },
              title: artifact.repository.name,
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
            articleDate: to_fhir_date(artifact.published_on),
            language: {
              coding: [
                {
                  system: 'urn:ietf:bcp:47',
                  code: 'en-US',
                  display: 'English (United States)'
                }
              ]
            }
          }
        ],
        webLocation: [
          {
            type: {
              coding: [
                {
                  system: 'http://terminology.hl7.org/CodeSystem/article-url-type',
                  code: artifact.url&.end_with?('.pdf') ? 'pdf' : 'full-text'
                }
              ]
            },
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
        classifier: keyword_list,
        whoClassified: {
          publisher: {
            reference: "Organization/#{artifact.repository.fhir_id}",
            display: artifact.repository.name
          }
        }
      )
    end

    if umls_concept_list.any?
      citation.citedArtifact.classification << FHIR::Citation::CitedArtifact::Classification.new(
        type: {
          coding: [
            {
              system: 'http://terminology.hl7.org/CodeSystem/cited-artifact-classification-type',
              code: 'keyword'
            }
          ]
        },
        classifier: umls_concept_list,
        whoClassified: {
          publisher: {
            display: 'AHRQ CEDAR'
          }
        }
      )
    end

    unless artifact.artifact_type.nil?
      citation.citedArtifact.classification << FHIR::Citation::CitedArtifact::Classification.new(
        type: {
          coding: [
            {
              system: 'http://terminology.hl7.org/CodeSystem/cited-artifact-classification-type',
              code: 'knowledge-artifact-type'
            }
          ]
        },
        classifier: [FHIR::CodeableConcept.new(text: artifact.artifact_type)]
      )
    end

    citation
  end

  def self.to_fhir_date(timestamp)
    timestamp&.strftime('%F')
  end

  def self.create_citation_bundle(total:, artifacts: nil, base_url: nil)
    bundle = FHIR::Bundle.new(
      type: 'searchset',
      total: total,
      link: []
    )

    return bundle if artifacts.nil?

    artifacts.each do |artifact|
      citation = create_citation(artifact, base_url)
      bundle.entry << FHIR::Bundle::Entry.new(
        resource: citation
      )
    end

    bundle
  end

  def self.create_organization(repository)
    FHIR::Organization.new(
      id: repository.fhir_id,
      name: repository.name,
      telecom: [
        {
          system: 'url',
          value: repository.home_page
        }
      ]
    )
  end

  def self.create_organization_bundle(repositories)
    FHIR::Bundle.new(
      type: 'searchset',
      total: repositories.length,
      link: [],
      entry: repositories.map do |r|
               FHIR::Bundle::Entry.new(
                 resource: create_organization(r)
               )
             end
    )
  end

  def self.create_mesh_children_output(mesh_tree_nodes)
    if mesh_tree_nodes.nil? || mesh_tree_nodes.empty?
      return FHIR::Parameters.new(
        parameter: []
      )
    end

    FHIR::Parameters.new(
      parameter: mesh_tree_nodes.map do |r|
        FHIR::Parameters::Parameter.new(
          name: 'concept',
          valueCoding: FHIR::Coding.new(
            extension: [
              FHIR::Extension.new(
                url: 'http://cedar.arhq.gov/StructureDefinition/extension-mesh-tree-number',
                valueCode: r.tree_number
              )
            ],
            code: r.code,
            system: 'http://terminology.hl7.org/CodeSystem/MSH',
            display: r.name
          )
        )
      end
    )
  end
end
