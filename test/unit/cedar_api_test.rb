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
    get '/1'
    assert last_response.ok?
    assert_equal({ 'id' => 1 }, JSON.parse(last_response.body))
  end
end
