# frozen_string_literal: true

require 'simplecov'
SimpleCov.start

# Set up as test environment before loading anything
require 'sinatra'
set :environment, :test

# Create the test database using the ActiveRecord database dump from cedar_admin
require 'active_record'
db_config = YAML.safe_load(File.open('test/db/config.yml'))
db_config_admin = db_config.merge(database: :postgres, schema_search_path: :public)
ActiveRecord::Base.establish_connection(db_config_admin)
ActiveRecord::Base.connection.drop_database(db_config['database'])
ActiveRecord::Base.connection.create_database(db_config['database'])
ActiveRecord::Base.establish_connection(db_config)
require_relative 'db/schema'

# Load the Sequel gem database config and set up fixtures
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
