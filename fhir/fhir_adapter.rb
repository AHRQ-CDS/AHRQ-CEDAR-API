# frozen_string_literal: true

require_relative './citation'
require_relative './fhir_code_systems'

# Service to read artifact from database and convert to FHIR resources
class FHIRAdapter
  include FHIRCodeSystems

  BASE_URL = 'https://cds.ahrq.gov/cedar/api/fhir'
  HOSTNAME = ENV['HOSTNAME'] || 'cds.ahrq.gov'
  SERVER_URL = "https://#{HOSTNAME}/cedar".freeze
  ARTIFACT_URL_CLICK_LOGGING = ENV['ARTIFACT_URL_CLICK_LOGGING'].to_s.downcase == 'true'

  def self.create_citation(artifact, artifact_base_url, redirect_base_url, version_id,
                           skip_concept: false,
                           result_index: 0,
                           search_id: 0)
    cedar_identifier = artifact[:cedar_identifier]
    # TODO: Put handling of JSONP array into model
    # TODO: Separate different types of keywords
    keywords = artifact.keywords
    keyword_list = keywords.map { |k| FHIR::CodeableConcept.new(text: k) }

    mesh_heading_list = []
    umls_concept_list = []

    unless skip_concept
      umls_concepts = artifact.concepts
      umls_concept_list = umls_concepts.map do |concept|
        codes = concept.codes.map do |code|
          if code['system'] == 'SCTSPA'
            {
              system: FHIR_CODE_SYSTEM_URLS['SNOMEDCT_US'],
              version: FHIR_CODE_SYSTEM_URLS['SCTSPA'],
              code: code['code'],
              display: code['description']
            }
          else
            {
              system: FHIR_CODE_SYSTEM_URLS[code['system']],
              code: code['code'],
              display: code['description']
            }
          end
        end
        mesh_heading = {
          system: FHIR_CODE_SYSTEM_URLS['MTH'],
          code: concept.umls_cui,
          display: concept.umls_description
        }
        codes << mesh_heading
        mesh_heading_list << FHIR::CodeableConcept.new(coding: [mesh_heading])
        FHIR::CodeableConcept.new(text: concept.umls_description, coding: codes)
      end
    end

    citation = FHIR::Citation.new(
      id: cedar_identifier,
      meta: {
        versionId: version_id.to_s
      },
      url: "#{artifact_base_url}/#{cedar_identifier}",
      identifier: [
        {
          system: SERVER_URL,
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
            value: SERVER_URL,
            use: 'work'
          }
        }
      ],
      # classification: Does CEDAR citation have its own keywords?
      copyright: get_copyright_markdown(artifact.repository),
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
              system: 'http://hl7.org/fhir/cited-artifact-status-type',
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
                  system: 'http://hl7.org/fhir/title-type',
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
                  system: 'http://hl7.org/fhir/cited-artifact-abstract-type',
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
                    system: 'http://hl7.org/fhir/published-in-type',
                    code: 'D019991',
                    display: 'Database'
                  }
                ]
              }
            },
            articleDate: to_fhir_date_with_precision(artifact.published_on, artifact.published_on_precision),
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
        ]
      }
    )

    if artifact.artifact_status != 'retracted'
      citation.citedArtifact.webLocation = []
      if ARTIFACT_URL_CLICK_LOGGING
        citation.citedArtifact.webLocation << {
          classifier: {
            text: 'CEDAR redirect'
          },
          url: "#{redirect_base_url}/#{cedar_identifier}?search=#{search_id}&result=#{result_index}"
        }
      end
      citation.citedArtifact.webLocation << {
        classifier: {
          coding: [
            {
              system: 'http://hl7.org/fhir/artifact-url-classifier',
              code: artifact.url&.end_with?('.pdf') ? 'pdf' : 'full-text'
            }
          ]
        },
        url: artifact.url
      }
    end

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
              system: 'http://hl7.org/fhir/cited-artifact-classification-type',
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
              system: 'http://hl7.org/fhir/cited-artifact-classification-type',
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

    if mesh_heading_list.any?
      citation.citedArtifact.classification << FHIR::Citation::CitedArtifact::Classification.new(
        type: {
          coding: [
            {
              system: 'http://hl7.org/fhir/cited-artifact-classification-type',
              code: 'mesh-heading'
            }
          ]
        },
        classifier: mesh_heading_list,
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
              system: 'http://hl7.org/fhir/cited-artifact-classification-type',
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
        url: "#{BASE_URL}/StructureDefinition/extension-#{property.gsub('_', '-')}",
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

  def self.get_copyright_markdown(repository)
    copyright_markdown = 'CEDAR indexes data from multiple source repositories and these repositories may have their ' \
                         'own content guidelines that govern the use of their data. More information on these ' \
                         'content guidelines can be found at the source repository sites.'

    case repository.fhir_id
    when 'srdr'
      return "#{copyright_markdown}\n\n* [SRDR Usage Policies](https://srdrplus.ahrq.gov/usage)"
    when 'uspstf'
      return "#{copyright_markdown}\n\n* [U.S. Preventive Services Task Force Copyright Notice]" \
             '(https://www.uspreventiveservicestaskforce.org/uspstf/recommendation-topics/copyright-notice)'
    when 'cds-connect'
      return "#{copyright_markdown}\n\n* [CDS Connect Disclaimer](https://cds.ahrq.gov/disclaimer)"
    end

    copyright_markdown
  end

  def self.to_quality_code(score)
    index = score.to_i.clamp(0, QUALITY_OF_EVIDENCE_CODES.size - 1)
    QUALITY_OF_EVIDENCE_CODES[index]
  end

  def self.to_fhir_date(timestamp)
    timestamp&.strftime('%F')
  end

  def self.to_fhir_date_with_precision(date, precision)
    case precision
    when 1
      date&.strftime('%Y')
    when 2
      date&.strftime('%Y-%m')
    # Default to day-level precision when nil. If the date is present but precision is nil, this likely indicates
    # a situation in which the artifact has been retracted, but we still have a date stored in the database.
    # Since we no longer have access to the original date string, we default to day-level precision.
    when 3..7, nil
      date&.strftime('%F')
    end
  end

  def self.create_citation_bundle(total:, artifacts: nil, artifact_base_url: nil,
                                  redirect_base_url: nil, offset: 0, search_id: 0)
    bundle = FHIR::Bundle.new(
      type: 'searchset',
      total: total,
      link: []
    )

    # Use the search ID as the Bundle ID if there's meaningful data in it
    bundle.id = search_id if search_id != 0

    return bundle if artifacts.nil?

    artifacts.each_with_index do |artifact, result_index|
      citation = create_citation(artifact, artifact_base_url, redirect_base_url,
                                 artifact.public_version_history.count + 1,
                                 result_index: offset + result_index, search_id: search_id)
      bundle_entry = FHIR::Bundle::Entry.new(
        resource: citation
      )

      if artifact[:rank].present?
        bundle_entry.extension << FHIR::Extension.new(
          url: "#{BASE_URL}/StructureDefinition/extension-content-search-rank",
          valueDecimal: artifact[:rank]
        )
      end

      bundle.entry << bundle_entry
    end

    bundle
  end

  def self.create_organization(repository)
    organization = FHIR::Organization.new(
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

    if repository.description.present?
      organization.extension << FHIR::Extension.new(
        url: "#{BASE_URL}/StructureDefinition/extension-organization-description",
        valueString: repository.description
      )
    end

    organization
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
                url: "#{BASE_URL}/StructureDefinition/extension-mesh-tree-number",
                valueCode: r.tree_number
              ),
              FHIR::Extension.new(
                url: "#{BASE_URL}/StructureDefinition/extension-mesh-has-children",
                valueBoolean: !(r.children.nil? || r.children.empty?)
              ),
              FHIR::Extension.new(
                url: "#{BASE_URL}/StructureDefinition/extension-mesh-direct-artifact-count",
                valueUnsignedInt: r.direct_artifact_count
              ),
              FHIR::Extension.new(
                url: "#{BASE_URL}/StructureDefinition/extension-mesh-indirect-artifact-count",
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
