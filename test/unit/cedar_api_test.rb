# frozen_string_literal: true

require_relative '../test_helper'

describe 'cedar_api' do
  include Rack::Test::Methods
  include CedarApi::TestHelper

  describe 'root' do
    it 'returns count of artifacts' do
      get '/'
      assert last_response.ok?
      assert_equal 'Artifact count: 1', last_response.body
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
    it 'returns resource when read with id' do
      get '/fhir/Citation/abc-1'

      assert last_response.ok?
      record = JSON.parse(last_response.body)
      assert_equal('Citation', record['resourceType'])
      assert_equal('abc-1', record['id'])
      assert_equal('active', record['status'])
    end

    it 'returns not found when read with invalid id' do
      get '/fhir/Citation/1000'
      assert last_response.not_found?
    end
  end
end

class CedarApiTest < MiniTest::Test
  include Rack::Test::Methods
  include CedarApi::TestHelper

  def test_root_return_count
    get '/'
    assert last_response.ok?
    assert_equal 'Artifact count: 3', last_response.body
  end

  def test_citation_found
    get '/fhir/Citation/abc-1'
    assert last_response.ok?
    record = JSON.parse(last_response.body)
    assert_equal('Citation', record['resourceType'])
    assert_equal('abc-1', record['id'])
    assert_equal('active', record['status'])
  end

  def test_citation_saerch_by_content
    get '/fhir/Citation?_content=cancer'
    assert last_response.ok?
    record = JSON.parse(last_response.body)
    assert_equal('Bundle', record['resourceType'])
    assert_equal('searchset', record['type'])
    assert_equal(1, record['total'])
  end

  def test_citation_saerch_by_title
    get '/fhir/Citation?title=diabetes'
    assert last_response.ok?
    record = JSON.parse(last_response.body)
    assert_equal('Bundle', record['resourceType'])
    assert_equal('searchset', record['type'])
    assert_equal(1, record['total'])
  end

  def test_citation_saerch_by_title_or
    get '/fhir/Citation?title=cancer,diabetes'
    assert last_response.ok?
    record = JSON.parse(last_response.body)
    assert_equal('Bundle', record['resourceType'])
    assert_equal('searchset', record['type'])
    assert_equal(2, record['total'])
  end

  def test_citation_saerch_by_title_contains
    get '/fhir/Citation?title:contains=diabetes'
    assert last_response.ok?
    record = JSON.parse(last_response.body)
    assert_equal('Bundle', record['resourceType'])
    assert_equal('searchset', record['type'])
    assert_equal(2, record['total'])
  end

  def test_root_not_found
    get '/foobar'
    assert last_response.not_found?
  end

  def test_other_resource_not_found
    get '/fhir/EvidenceReport/1000'
    assert last_response.not_found?
  end

  def test_citation_not_found
    get '/fhir/Citation/1000'
    assert last_response.not_found?
  end
end
