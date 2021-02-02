# frozen_string_literal: true

require_relative '../test_helper'

class CedarApiTest < MiniTest::Test
  include Rack::Test::Methods
  include CedarApi::TestHelper

  def test_root_return_count
    get '/'
    assert last_response.ok?
    assert_equal 'Artifact count: 1', last_response.body
  end

  def test_citation_found
    get '/fhir/Citation/abc-1'
    assert last_response.ok?
    record = JSON.parse(last_response.body)
    assert_equal('Citation', record['resourceType'])
    assert_equal('abc-1', record['id'])
    assert_equal('active', record['status'])
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
