# frozen_string_literal: true

require_relative './citation'
require_relative './fhir_code_systems'

# Service to read artifact from database and convert to FHIR resources
class FHIRAdapter
  include FHIRCodeSystems

  HOSTNAME = ENV['HOSTNAME'] || 'http://cedar.arhq.gov'
  ARTIFACT_URL_CLICK_LOGGING = ENV['ARTIFACT_URL_CLICK_LOGGING'].to_s.downcase == 'true'

  def self.create_citation(artifact, artifact_base_url, redirect_base_url, version_id, skip_concept: false)
    cedar_identifier = artifact[:cedar_identifier]
    # TODO: Put handling of JSONP array into model
    # TODO: Separate different types of keywords
    keywords = artifact.keywords
    keyword_list = keywords.map { |k| FHIR::CodeableConcept.new(text: k) }

    if skip_concept
      umls_concept_list = []
    else
      umls_concepts = artifact.concepts
      umls_concept_list = umls_concepts.map do |concept|
        codes = concept.codes.map do |c|
          {
            system: FHIR_CODE_SYSTEM_URLS[c['system']],
            code: c['code'],
            display: c['description']
          }
        end
        codes << {
          system: FHIR_CODE_SYSTEM_URLS['MTH'],
          code: concept.umls_cui,
          display: concept.umls_description
        }
        FHIR::CodeableConcept.new(text: concept.umls_description, coding: codes)
      end
    end

    citation = FHIR::Citation.new(
      id: cedar_identifier,
      meta: {
        versionId: version_id
      },
      url: "#{artifact_base_url}/#{cedar_identifier}",
      identifier: [
        {
          system: HOSTNAME,
          value: cedar_identifier
        }
      ],
      title: artifact.title,
      status: artifact.artifact_status == 'retracted' ? 'retired' : 'active',
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
            system: if artifact.remote_identifier&.match(%r{^https?://.+})
                      'urn:ietf:rfc:3986'
                    else
                      artifact.repository.home_page
                    end,
            value: artifact.remote_identifier
          }
        ],
        dateAccessed: to_fhir_date(artifact.updated_at),
        currentState: [
          {
            coding: {
              system: 'http://terminology.hl7.org/CodeSystem/cited-artifact-status-type',
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
                  code: 'primary',
                  display: 'Primary title'
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
        webLocation: if artifact.artifact_status == 'retracted'
                       nil
                     else
                       [
                         {
                           classifier: {
                             coding: [
                               {
                                 system: 'http://terminology.hl7.org/CodeSystem/artifact-url-classifier',
                                 code: artifact.url&.end_with?('.pdf') ? 'pdf' : 'full-text'
                               }
                             ]
                           },
                           url: if ARTIFACT_URL_CLICK_LOGGING
                                  "#{redirect_base_url}/#{cedar_identifier}"
                                else
                                  artifact.url
                                end
                         }
                       ]
                     end
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
        artifactAssessment: {
          display: 'Classified by AHRQ CEDAR'
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

    %w[strength_of_recommendation quality_of_evidence].each do |property|
      next if artifact.send("#{property}_statement").nil? && artifact.send("#{property}_score").nil?

      code = to_quality_code(artifact.send("#{property}_sort"))
      ext = FHIR::Extension.new(
        url: "http://cedar.arhq.gov/StructureDefinition/extension-#{property.gsub('_', '-')}",
        valueCodeableConcept: FHIR::CodeableConcept.new(
          text: artifact.send("#{property}_statement"),
          coding: [
            FHIR::Coding.new(
              code: code[:code],
              system: 'http://terminology.hl7.org/CodeSystem/certainty-rating',
              display: code[:display]
            )
          ]
        )
      )
      if artifact.send("#{property}_score").present?
        ext.valueCodeableConcept.coding << FHIR::Coding.new(
          display: artifact.send("#{property}_score"),
          userSelected: true
        )
      end
      citation.citedArtifact.extension << ext
    end

    citation
  end

  def self.to_quality_code(score)
    index = score.to_i.clamp(0, QUALITY_OF_EVIDENCE_CODES.size - 1)
    QUALITY_OF_EVIDENCE_CODES[index]
  end

  def self.to_fhir_date(timestamp)
    timestamp&.strftime('%F')
  end

  def self.create_citation_bundle(total:, artifacts: nil, artifact_base_url: nil, redirect_base_url: nil)
    bundle = FHIR::Bundle.new(
      type: 'searchset',
      total: total,
      link: []
    )

    return bundle if artifacts.nil?

    artifacts.each do |artifact|
      citation = create_citation(artifact, artifact_base_url, redirect_base_url, artifact.versions.count + 1)
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
      alias: [
        repository.alias
      ],
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
              ),
              FHIR::Extension.new(
                url: 'http://cedar.arhq.gov/StructureDefinition/extension-mesh-has-children',
                valueBoolean: !(r.children.nil? || r.children.empty?)
              ),
              FHIR::Extension.new(
                url: 'http://cedar.arhq.gov/StructureDefinition/extension-mesh-direct-artifact-count',
                valueUnsignedInt: r.direct_artifact_count
              ),
              FHIR::Extension.new(
                url: 'http://cedar.arhq.gov/StructureDefinition/extension-mesh-indirect-artifact-count',
                valueUnsignedInt: r.indirect_artifact_count
              )
            ],
            code: r.code,
            system: FHIR_CODE_SYSTEM_URLS['MSH'],
            display: r.name
          )
        )
      end
    )
  end

  def self.create_artifact_types_output(artifact_types)
    if artifact_types.nil? || artifact_types.empty?
      return FHIR::Parameters.new(
        parameter: []
      )
    end

    FHIR::Parameters.new(
      parameter: artifact_types.map do |r|
        FHIR::Parameters::Parameter.new(
          name: 'artifact-type',
          valueCoding: FHIR::Coding.new(
            display: r.artifact_type
          )
        )
      end
    )
  end
end
