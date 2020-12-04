# frozen_string_literal: true

require 'simplecov'
SimpleCov.start

require_relative '../cedar_api'
require 'minitest/autorun'
require 'rack/test'

set :environment, :test

module CedarApi
  module TestHelper
    def app
      Sinatra::Application
    end
  end
end
