# frozen_string_literal: true

require 'simplecov'
SimpleCov.start

# Set up as test environment before loading anything
require 'sinatra'
set :environment, :test

# Load database config and set up fixtures
require_relative '../database/setup'
require_relative './fixtures'

require_relative '../cedar_api'
require 'minitest/autorun'
require 'rack/test'

module CedarApi
  module TestHelper
    def app
      Sinatra::Application
    end
  end
end
