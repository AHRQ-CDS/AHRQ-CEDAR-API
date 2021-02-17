# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../database/models'

describe 'cedar_api' do
  include Rack::Test::Methods
  include CedarApi::TestHelper

  def assert_bundle
    assert last_response.ok?
    bundle = FHIR.from_contents(last_response.body)

    refute_nil bundle
    assert bundle.is_a?(FHIR::Bundle)
    assert_equal 'searchset', bundle.type
    assert_equal bundle.total, bundle.entry.size
    assert bundle.entry.size.positive?

    bundle
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

      assert last_response.ok?
      resource = FHIR.from_contents(last_response.body)
      refute_nil resource
      assert resource.is_a?(FHIR::CapabilityStatement)
    end

    it 'returns not found for not supported resource type' do
      get '/fhir/EvidenceReport/1000'
      assert last_response.not_found?
    end
  end

  describe '/fhir/Citation endpoint' do
    it 'supports read with id' do
      get '/fhir/Citation/abc-1'

      assert last_response.ok?
      resource = FHIR.from_contents(last_response.body)

      refute_nil resource
      assert resource.is_a?(FHIR::Citation)
      assert_equal 'abc-1', resource.id
      assert_equal 'active', resource.status
    end

    it 'returns not found when read with invalid id' do
      get '/fhir/Citation/1000'
      assert last_response.not_found?
    end

    it 'supports search by _content' do
      get '/fhir/Citation?_content=cancer'
      bundle = assert_bundle

      assert bundle.entry.all? do |entry|
        entry.resource.title.downcase.include?('cancer') ||
          entry.resource.description.downcase.include?('cancer')
      end
    end

    it 'supports search by title' do
      get '/fhir/Citation?title=diabetes'
      bundle = assert_bundle
      assert bundle.entry.all? do |entry|
        entry.resource.title.downcase.start_with?('diabetes')
      end
    end

    it 'supports search by title with multiple OR' do
      get '/fhir/Citation?title=cancer,diabetes'
      bundle = assert_bundle
      assert bundle.entry.all? do |entry|
        entry.resource.title.downcase.start_with?('diabetes') ||
          entry.resource.title.downcase.start_with?('cancer')
      end
    end

    it 'support search by title with :contains modifier' do
      get '/fhir/Citation?title:contains=diabetes'
      bundle = assert_bundle
      assert bundle.entry.all? do |entry|
        entry.resource.title.downcase.include?('diabetes')
      end
    end

    it 'support search by keyword' do
      get '/fhir/Citation?keyword=diabetes'
      bundle = assert_bundle
      assert bundle.entry.all? do |entry|
        entry.resource.keywordList.any? do |keyword_list|
          keyword_list.keyword.any { |keyword| keyword.value.downcase == 'diabetes' }
        end
      end
    end

    it 'support search by keyword with multiple OR' do
      get '/fhir/Citation?keyword=diabetes,Adult'
      bundle = assert_bundle
      assert bundle.entry.all? do |entry|
        entry.resource.keywordList.any? do |keyword_list|
          keyword_list.keyword.any do |keyword|
            keyword.value.downcase == 'diabetes' || keyword.value.downcase == 'adult'
          end
        end
      end
    end
  end
end
