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

  def test_id_return_json
    get '/artifact/1'
    assert last_response.ok?
    assert_equal({ 'id' => 1, 'remote_identifier' => 1 }, JSON.parse(last_response.body))
  end

  def test_root_not_found
    get '/foobar'
    assert last_response.not_found?
  end

  def test_artifact_not_found
    get '/artifact/1000'
    assert last_response.not_found?
  end

  def test_evidence_not_found
    get '/fhir/EvidenceReport/1000'
    assert last_response.not_found?
  end

  def test_plan_not_found
    get '/fhir/PlanDefinition/1000'
    assert last_response.not_found?
  end

  def test_citation_not_found
    get '/fhir/Citation/1000'
    assert last_response.not_found?
  end
end
