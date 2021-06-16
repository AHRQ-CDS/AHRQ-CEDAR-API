# frozen_string_literal: true

require 'warning'
require_relative '../test_helper'
require_relative '../../database/models'
require 'warning'

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
      assert_equal 1, resource.citedArtifact.classification[1].classifier[0].coding.size
      assert_equal 'D0001', resource.citedArtifact.classification[1].classifier[0].coding[0].code
      assert_equal 'https://www.nlm.nih.gov/mesh/',
                   resource.citedArtifact.classification[1].classifier[0].coding[0].system
      assert_equal 0, resource.citedArtifact.classification[1].classifier[1].coding.size
    end

    it 'returns not found when read with invalid id' do
      get '/fhir/Citation/1000'
      assert last_response.not_found?
    end

    it 'supports search by _content' do
      Warning.ignore(/extra states are no longer copied/)
      get '/fhir/Citation?_content=cancer&artifact-current-state=active'
      bundle = assert_fhir_response(FHIR::Bundle)
      assert bundle.entry.all? do |entry|
        entry.resource.title.downcase.include?('cancer') ||
          entry.resource.description.downcase.include?('cancer')
      end
    end

    it 'supports search by title' do
      get '/fhir/Citation?title=diabetes&artifact-current-state=active'
      bundle = assert_fhir_response(FHIR::Bundle)
      assert bundle.entry.all? do |entry|
        entry.resource.title.downcase.start_with?('diabetes')
      end
    end

    it 'supports search by title with multiple OR' do
      get '/fhir/Citation?title=cancer,diabetes&artifact-current-state=active'
      bundle = assert_fhir_response(FHIR::Bundle)
      assert bundle.entry.all? do |entry|
        entry.resource.title.downcase.start_with?('diabetes') ||
          entry.resource.title.downcase.start_with?('cancer')
      end
    end

    it 'supports search by title with :contains modifier' do
      get '/fhir/Citation?title:contains=diabetes&artifact-current-state=active'
      bundle = assert_fhir_response(FHIR::Bundle)
      assert bundle.entry.all? do |entry|
        entry.resource.title.downcase.include?('diabetes')
      end
    end

    it 'supports search by classification text' do
      get '/fhir/Citation?classification:text=diabetes&artifact-current-state=active'
      bundle = assert_fhir_response(FHIR::Bundle)
      assert bundle.entry.all? do |entry|
        entry.resource.keywordList.any? do |keyword_list|
          keyword_list.keyword.any { |keyword| keyword.value.downcase == 'diabetes' }
        end
      end
    end

    it 'supports search by classification text with multiple OR' do
      get '/fhir/Citation?classification:text=diabetes OR adult&artifact-current-state=active'
      bundle = assert_fhir_response(FHIR::Bundle)
      assert bundle.entry.all? do |entry|
        entry.resource.keywordList.any? do |keyword_list|
          keyword_list.keyword.any do |keyword|
            keyword.value.downcase == 'diabetes' || keyword.value.downcase == 'adult'
          end
        end
      end
    end

    it 'supports search by classification system and code' do
      get '/fhir/Citation?' \
          "classification=#{URI.encode_www_form_component('https://www.nlm.nih.gov/mesh/|D0001')}" \
          '&artifact-current-state=active'
      bundle = assert_fhir_response(FHIR::Bundle)
      assert bundle.entry.all? do |entry|
        entry.resource.keywordList.any? do |keyword_list|
          keyword_list.keyword.any { |keyword| keyword.value.downcase == 'cancer' }
        end
      end
    end

    it 'supports search by classification code' do
      get '/fhir/Citation?classification=D0001&artifact-current-state=active'
      bundle = assert_fhir_response(FHIR::Bundle)
      assert bundle.entry.all? do |entry|
        entry.resource.keywordList.any? do |keyword_list|
          keyword_list.keyword.any { |keyword| keyword.value.downcase == 'cancer' }
        end
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

    it 'returns Citations' do
      Warning.ignore(/instance variable @\w+ not initialized/)
      get '/fhir/Citation?_content=cancer&artifact-current-state=active'
      assert_fhir_response(FHIR::Bundle)
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
end
