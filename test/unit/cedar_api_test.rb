# frozen_string_literal: true

require_relative '../test_helper'

class CedarApiTest < MiniTest::Test
  include Rack::Test::Methods
  include CedarApi::TestHelper

  def test_root_return_hello_world
    get '/'
    assert last_response.ok?
    assert_equal 'Hello World!', last_response.body
  end
end
