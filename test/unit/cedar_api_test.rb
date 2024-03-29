# frozen_string_literal: true

require 'set'
require 'warning'
require_relative '../test_helper'
require_relative '../../database/models'
require_relative '../../fhir/fhir_code_systems'
require_relative '../../fhir/fhir_adapter'

describe 'cedar_api' do
  include Rack::Test::Methods
  include CedarApi::TestHelper

  let(:code_system_consts) { Class.new { extend FHIRCodeSystems } }

  def assert_fhir_response(resource_class)
    assert_predicate last_response, :ok?
    resource = FHIR.from_contents(last_response.body)

    refute_nil resource
    assert resource.is_a?(resource_class)

    resource
  end

  describe 'root' do
    it 'returns count of artifacts' do
      get '/'

      assert_predicate last_response, :ok?
      assert_equal "Artifact count: #{Artifact.count}", last_response.body
    end

    it 'returns not found when endpoint does not exist' do
      get '/foobar'

      assert_predicate last_response, :not_found?
    end
  end

  describe 'suggestions' do
    it 'returns distinct suggestions and term' do
      get '/suggestions?term=Child'

      assert_predicate last_response, :ok?
      assert_equal 'application/json', last_response.content_type

      json_data = JSON.parse(last_response.body)

      assert_kind_of Array, json_data['suggestions']
      assert_kind_of String, json_data['term']

      assert_equal json_data['suggestions'].to_set.length, json_data['suggestions'].length
      assert_equal 'Child', json_data['term']
    end

    it 'returns empty suggestions for empty term' do
      get '/suggestions?term='

      assert_predicate last_response, :ok?
      assert_equal 'application/json', last_response.content_type

      json_data = JSON.parse(last_response.body)

      assert_equal 0, json_data['suggestions'].length
      assert_equal '', json_data['term']
    end

    it 'returns 400 when missing term' do
      get '/suggestions'

      assert_predicate last_response, :bad_request?
    end
  end

  describe '/redirect endpoint' do
    it 'returns 404 for unknown artifacts' do
      get '/redirect/foo'

      assert_predicate last_response, :not_found?
    end

    it 'returns a redirect for known artifacts' do
      get '/redirect/abc-1'

      assert_predicate last_response, :redirect?
      assert_equal 'http://example.org/abc-1', last_response.location
    end
  end

  describe '/csv endpoint' do
    it 'returns a valid CSV file' do
      get '/csv?_content=cancer&artifact-current-state=active'

      assert_predicate last_response, :ok?
      data = CSV.parse(last_response.body, headers: true)
      row = data.first.to_h

      assert_includes row.keys, 'Repository'
      refute_nil row['Repository']
      assert_includes row.keys, 'Title'
      refute_nil row['Title']
    end

    it 'validates search parameter values' do
      get 'csv?_content=cancer&artifact-current-state=active&_lastUpdated=et1990-01-01'

      assert_predicate last_response, :server_error?
    end
  end

  describe '/fhir endpoint' do
    it 'returns CapabilityStatement from /metadata endpoint' do
      get '/fhir/metadata'

      assert_fhir_response(FHIR::CapabilityStatement)
    end

    it 'returns not found for not supported resource type' do
      get '/fhir/EvidenceReport/1000'

      assert_predicate last_response, :not_found?
    end
  end

  describe '/fhir/Citation endpoint' do
    it 'supports read with id' do
      artifact = Artifact.first(cedar_identifier: 'abc-1')

      get '/fhir/Citation/abc-1'

      resource = assert_fhir_response(FHIR::Citation)

      assert_equal 'abc-1', resource.id
      assert_equal 'active', resource.status
      assert_equal 'active', resource.citedArtifact.currentState[0].coding[0].code
      refute_nil resource.url
      assert_equal 3, resource.citedArtifact.classification.size
      assert_equal 2, resource.citedArtifact.classification[1].classifier.size
      assert_equal 'CUI1 desc', resource.citedArtifact.classification[1].classifier[0].text
      assert_equal 'CUI2 desc', resource.citedArtifact.classification[1].classifier[1].text
      assert_equal 3, resource.citedArtifact.classification[1].classifier[0].coding.size
      assert_equal 'D0001', resource.citedArtifact.classification[1].classifier[0].coding[0].code
      assert_equal FHIRCodeSystems::FHIR_CODE_SYSTEM_URLS['MSH'],
                   resource.citedArtifact.classification[1].classifier[0].coding[0].system
      assert_equal '10001', resource.citedArtifact.classification[1].classifier[0].coding[1].code
      assert_equal FHIRCodeSystems::FHIR_CODE_SYSTEM_URLS['SNOMEDCT_US'],
                   resource.citedArtifact.classification[1].classifier[0].coding[1].system
      assert_equal 2, resource.citedArtifact.classification[1].classifier[1].coding.size
      assert_equal (artifact.public_version_history.count + 1).to_s, resource.meta.versionId
    end

    it 'supports deleted artifacts' do
      get '/fhir/Citation/abc-4'

      resource = assert_fhir_response(FHIR::Citation)

      assert_equal 'abc-4', resource.id
      assert_equal 'retired', resource.status
      assert_equal 'retracted', resource.citedArtifact.currentState[0].coding[0].code
      assert_empty resource.citedArtifact.webLocation
    end

    it 'returns not found when read with invalid id' do
      get '/fhir/Citation/1000'

      assert_predicate last_response, :not_found?
    end

    it 'supports search by _content' do
      Warning.ignore(/extra states are no longer copied/)
      Warning.ignore(/instance variable @\w+ not initialized/)
      get '/fhir/Citation?_content=cancer&artifact-current-state=active'
      bundle = assert_fhir_response(FHIR::Bundle)
      assert_predicate bundle.entry, :all? do |entry|
        entry.resource.title.downcase.include?('cancer') ||
          entry.resource.description.downcase.include?('cancer')
      end
    end

    it 'requires artifact-current-state search parameter' do
      get 'fhir/Citation?_content=cancer'

      resource = assert_fhir_response(FHIR::OperationOutcome)

      assert_predicate resource.issue.size, :positive?
      assert_predicate resource.issue, :any? do |issue|
        issue.severity == 'error' && issue.code == 'required'
      end
    end

    it 'validates search parameter values' do
      get 'fhir/Citation?_content=cancer&artifact-current-state=active&_lastUpdated=et1990-01-01'

      resource = assert_fhir_response(FHIR::OperationOutcome)

      assert_predicate resource.issue.size, :positive?
      assert_predicate resource.issue, :any? do |issue|
        issue.severity == 'error' && issue.code == 'value'
      end
    end

    it 'returns version number for all artifacts' do
      Warning.ignore(/extra states are no longer copied/)
      get '/fhir/Citation?_content=cancer&artifact-current-state=active'
      bundle = assert_fhir_response(FHIR::Bundle)
      bundle.entry.each do |entry|
        artifact = Artifact.first(cedar_identifier: entry.resource.id)

        assert_equal (artifact.public_version_history.count + 1).to_s, entry.resource.meta.versionId
      end
    end

    it 'returns 404 if version id is 0' do
      cedar_identifier = 'abc-1'
      get "fhir/Citation/#{cedar_identifier}/_history/0"

      assert_predicate last_response, :not_found?
    end

    it 'supports read history with version id for a historical version' do
      cedar_identifier = 'abc-1'
      artifact = Artifact.first(cedar_identifier: cedar_identifier)

      get "fhir/Citation/#{cedar_identifier}/_history/1"

      resource = assert_fhir_response(FHIR::Citation)

      assert_equal cedar_identifier, resource.id
      assert_equal '1', resource.meta.versionId
      assert_equal artifact.public_version_history.first.object['title'], resource.title
    end

    it 'supports read history with version id for the current version' do
      cedar_identifier = 'abc-1'
      artifact = Artifact.first(cedar_identifier: cedar_identifier)
      latest_version = artifact.public_version_history.count + 1

      get "fhir/Citation/#{cedar_identifier}/_history/#{latest_version}"

      resource = assert_fhir_response(FHIR::Citation)

      assert_equal cedar_identifier, resource.id
      assert_equal latest_version.to_s, resource.meta.versionId
      assert_equal artifact.title, resource.title
    end

    it 'returns 404 if version id is > latest version' do
      cedar_identifier = 'abc-1'
      artifact = Artifact.first(cedar_identifier: cedar_identifier)
      latest_version = artifact.public_version_history.count + 1

      get "fhir/Citation/#{cedar_identifier}/_history/#{latest_version + 1}"

      assert_predicate last_response, :not_found?
    end

    it 'shows the articleDate with the appropriate precision for year precision' do
      cedar_identifier = 'abc-5'
      artifact = Artifact.first(cedar_identifier: cedar_identifier)

      get "fhir/Citation/#{cedar_identifier}"

      resource = assert_fhir_response(FHIR::Citation)

      assert_equal(artifact.published_on.strftime('%Y'), resource.citedArtifact.publicationForm[0].articleDate)
    end

    it 'shows the articleDate with the appropriate precision for year-month precision' do
      cedar_identifier = 'abc-6'
      artifact = Artifact.first(cedar_identifier: cedar_identifier)

      get "fhir/Citation/#{cedar_identifier}"

      resource = assert_fhir_response(FHIR::Citation)

      assert_equal(artifact.published_on.strftime('%Y-%m'), resource.citedArtifact.publicationForm[0].articleDate)
    end

    it 'shows the articleDate with the appropriate precision for year-month-day precision' do
      cedar_identifier = 'abc-2'
      artifact = Artifact.first(cedar_identifier: cedar_identifier)

      get "fhir/Citation/#{cedar_identifier}"

      resource = assert_fhir_response(FHIR::Citation)

      assert_equal(artifact.published_on.strftime('%F'), resource.citedArtifact.publicationForm[0].articleDate)
    end

    it 'supports repository specific copyright' do
      cedar_identifier = 'abc-1'

      get "fhir/Citation/#{cedar_identifier}"

      resource = assert_fhir_response(FHIR::Citation)

      assert_includes(resource.copyright, 'U.S. Preventive Services Task Force Copyright')
    end
  end

  describe '/fhir/Citation/$get-artifact-types endpoint' do
    it 'gets artifact types in Parameter' do
      get '/fhir/Citation/$get-artifact-types'

      resource = assert_fhir_response(FHIR::Parameters)
      resource.parameter.each do |p|
        assert_equal('artifact-type', p.name)
        assert_predicate p.valueCoding.display, :present?
      end
    end
  end

  describe '/fhir/Organization endpoint' do
    it 'supports read by id' do
      repo_id = 'uspstf'
      get "/fhir/Organization/#{repo_id}"

      resource = assert_fhir_response(FHIR::Organization)

      assert_equal(repo_id, resource.id)
    end

    it 'supports read all repositories' do
      get '/fhir/Organization'

      resource = assert_fhir_response(FHIR::Bundle)

      assert_equal(resource.total, Repository.count)
      assert_equal(resource.total, resource.entry.length)
    end
  end

  describe '/fhir/CodeSystem/$get-mesh-children endpoint' do
    it 'gets child tree nodes with parent tree number' do
      get '/fhir/CodeSystem/$get-mesh-children?code=A00'

      resource = assert_fhir_response(FHIR::Parameters)

      assert_equal(MeshTreeNode.where(parent_id: 401).count, resource.parameter.count)
      resource.parameter.each do |p|
        extensions_present = {}
        p.valueCoding.extension.each do |e|
          extensions_present[e.url] = true
          case e.url
          when "#{FHIRAdapter::BASE_URL}/StructureDefinition/extension-mesh-tree-number"

            assert_includes(['A00.1', 'A00.2'], e.valueCode)
          when "#{FHIRAdapter::BASE_URL}/StructureDefinition/extension-mesh-has-children"

            refute e.valueBoolean
          when "#{FHIRAdapter::BASE_URL}/StructureDefinition/extension-mesh-direct-artifact-count"

            assert_equal(1, e.valueUnsignedInt)
          when "#{FHIRAdapter::BASE_URL}/StructureDefinition/extension-mesh-indirect-artifact-count"

            assert_equal(0, e.valueUnsignedInt)
          end
        end

        assert_equal(4, extensions_present.size)
      end
    end

    it 'gets first level tree nodes without parenet tree number' do
      get '/fhir/CodeSystem/$get-mesh-children'

      resource = assert_fhir_response(FHIR::Parameters)

      assert_equal(1, resource.parameter.count)
      extensions_present = {}
      resource.parameter[0].valueCoding.extension.each do |e|
        extensions_present[e.url] = true
        case e.url
        when "#{FHIRAdapter::BASE_URL}/StructureDefinition/extension-mesh-tree-number"

          assert_equal('A00', e.valueCode)
        when "#{FHIRAdapter::BASE_URL}/StructureDefinition/extension-mesh-has-children"

          assert e.valueBoolean
        when "#{FHIRAdapter::BASE_URL}/StructureDefinition/extension-mesh-direct-artifact-count"

          assert_equal(0, e.valueUnsignedInt)
        when "#{FHIRAdapter::BASE_URL}/StructureDefinition/extension-mesh-indirect-artifact-count"

          assert_equal(2, e.valueUnsignedInt)
        end
      end

      assert_equal(4, extensions_present.size)
    end
  end

  describe '/fhir/SearchParameter endpoint' do
    it 'supports search by url' do
      url = "#{FHIRAdapter::BASE_URL}/SearchParameter/cedar-citation-artifact-current-state"
      get "/fhir/SearchParameter?url=#{url}"

      resource = assert_fhir_response(FHIR::SearchParameter)

      assert_equal(resource.url, url)
    end

    it 'supports read by id' do
      id = 'cedar-citation-artifact-current-state'
      get "/fhir/SearchParameter/#{id}"
      resource = assert_fhir_response(FHIR::SearchParameter)

      assert_equal(id, resource.id)
    end

    it 'returns 404 if not found' do
      id = 'unknown'
      get "/fhir/SearchParameter/#{id}"

      assert_predicate last_response, :not_found?
    end
  end
end
