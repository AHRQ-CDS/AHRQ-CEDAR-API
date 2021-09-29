# frozen_string_literal: true

require 'warning'
require_relative '../test_helper'
require_relative '../../database/models'

describe 'cedar_api' do
  include Rack::Test::Methods
  include CedarApi::TestHelper

  def assert_fhir_response(resource_class)
    assert last_response.ok?
    resource = FHIR.from_contents(last_response.body)

    refute_nil resource
    assert resource.is_a?(resource_class)

    resource
  end

  describe 'root' do
    it 'returns count of artifacts' do
      get '/'
      assert last_response.ok?
      assert_equal "Artifact count: #{Artifact.count}", last_response.body
    end

    it 'returns not found when endpoint does not exist' do
      get '/foobar'
      assert last_response.not_found?
    end
  end

  describe '/fhir endpoint' do
    it 'returns CapabilityStatement from /metadata endpoint' do
      get '/fhir/metadata'

      assert_fhir_response(FHIR::CapabilityStatement)
    end

    it 'returns not found for not supported resource type' do
      get '/fhir/EvidenceReport/1000'
      assert last_response.not_found?
    end
  end

  describe '/fhir/Citation endpoint' do
    it 'supports read with id' do
      get '/fhir/Citation/abc-1'

      resource = assert_fhir_response(FHIR::Citation)
      assert_equal 'abc-1', resource.id
      assert_equal 'active', resource.status
      assert_equal 2, resource.citedArtifact.classification.size
      assert_equal 2, resource.citedArtifact.classification[1].classifier.size
      assert_equal 'CUI1 desc', resource.citedArtifact.classification[1].classifier[0].text
      assert_equal 'CUI2 desc', resource.citedArtifact.classification[1].classifier[1].text
      assert_equal 2, resource.citedArtifact.classification[1].classifier[0].coding.size
      assert_equal 'D0001', resource.citedArtifact.classification[1].classifier[0].coding[0].code
      assert_equal 'https://www.nlm.nih.gov/mesh/',
                   resource.citedArtifact.classification[1].classifier[0].coding[0].system
      assert_equal 'D0002', resource.citedArtifact.classification[1].classifier[0].coding[1].code
      assert_equal 'https://www.nlm.nih.gov/mesh/',
                   resource.citedArtifact.classification[1].classifier[0].coding[1].system
      assert_equal 0, resource.citedArtifact.classification[1].classifier[1].coding.size
    end

    it 'returns not found when read with invalid id' do
      get '/fhir/Citation/1000'
      assert last_response.not_found?
    end

    it 'supports search by _content' do
      Warning.ignore(/extra states are no longer copied/)
      Warning.ignore(/instance variable @\w+ not initialized/)
      get '/fhir/Citation?_content=cancer&artifact-current-state=active'
      bundle = assert_fhir_response(FHIR::Bundle)
      assert bundle.entry.all? do |entry|
        entry.resource.title.downcase.include?('cancer') ||
          entry.resource.description.downcase.include?('cancer')
      end
    end

    it 'requires artifact-current-state search parameter' do
      get 'fhir/Citation?_content=cancer'

      resource = assert_fhir_response(FHIR::OperationOutcome)
      assert resource.issue.size.positive?
      assert resource.issue.any? do |issue|
        issue.severity == 'error' && issue.code == 'required'
      end
    end

    it 'validate search parameter values' do
      get 'fhir/Citation?_content=cancer&artifact-current-state=active&_lastUpdated=et1990-01-01'

      resource = assert_fhir_response(FHIR::OperationOutcome)
      assert resource.issue.size.positive?
      assert resource.issue.any? do |issue|
        issue.severity == 'error' && issue.code == 'value'
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
          when 'http://cedar.arhq.gov/StructureDefinition/extension-mesh-tree-number'
            assert_includes(['A00.1', 'A00.2'], e.valueCode)
          when 'http://cedar.arhq.gov/StructureDefinition/extension-mesh-has-children'
            refute e.valueBoolean
          when 'http://cedar.arhq.gov/StructureDefinition/extension-mesh-direct-artifact-count'
            assert_equal(1, e.valueUnsignedInt)
          when 'http://cedar.arhq.gov/StructureDefinition/extension-mesh-indirect-artifact-count'
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
        when 'http://cedar.arhq.gov/StructureDefinition/extension-mesh-tree-number'
          assert_equal('A00', e.valueCode)
        when 'http://cedar.arhq.gov/StructureDefinition/extension-mesh-has-children'
          assert e.valueBoolean
        when 'http://cedar.arhq.gov/StructureDefinition/extension-mesh-direct-artifact-count'
          assert_equal(0, e.valueUnsignedInt)
        when 'http://cedar.arhq.gov/StructureDefinition/extension-mesh-indirect-artifact-count'
          assert_equal(2, e.valueUnsignedInt)
        end
      end
      assert_equal(4, extensions_present.size)
    end
  end

  describe '/fhir/SearchParameter endpoint' do
    it 'supports search by url' do
      url = 'http://cedar.ahrq.gov/fhir/SearchParameter/cedar-citiation-artifact-current-state'
      get "/fhir/SearchParameter?url=#{url}"

      resource = assert_fhir_response(FHIR::SearchParameter)
      assert_equal(resource.url, url)
    end

    it 'supports read by id' do
      id = 'cedar-citiation-artifact-current-state'
      get "/fhir/SearchParameter/#{id}"
      resource = assert_fhir_response(FHIR::SearchParameter)
      assert_equal(id, resource.id)
    end

    it 'returns 404 if not found' do
      id = 'unknown'
      get "/fhir/SearchParameter/#{id}"
      assert last_response.not_found?
    end
  end
end
