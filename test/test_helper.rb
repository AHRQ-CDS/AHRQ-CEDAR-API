# frozen_string_literal: true

# Ignore warnings from included gems
# The Sequel gem generates a lot of (harmless) uninitialized instance variable warnings
Gem.path.each do |path|
  Warning.ignore(//, path)
end

require 'simplecov'
SimpleCov.start

# Set up as test environment before loading anything
require 'sinatra'
set :environment, :test

# Create the test database using the ActiveRecord database dump from cedar_admin
# ActiveRecord uses a different name (postgresql) for the PostgreSQL adapter than
# Sequel (postgres) so we have to patch that after loading the database config
require 'active_record'
test_db_config = YAML.safe_load(ERB.new(File.read('database/config.yml')).result)['test']
test_db_config.merge!(adapter: :postgresql)

# Drop and recreate the test database, to do this we need to connect to the PostgreSQL admin database called 'postgres'
admin_db_config = test_db_config.merge(database: :postgres, schema_search_path: :public)
ActiveRecord::Base.establish_connection(admin_db_config)
ActiveRecord::Base.connection.drop_database(test_db_config['database'])
ActiveRecord::Base.connection.create_database(test_db_config['database'])

# Load the database schema dumped from cedar_admin
ActiveRecord::Base.establish_connection(test_db_config)
ActiveRecord::Migration.verbose = false
require_relative 'db/schema'

# Load the Sequel gem database config and set up fixtures
require_relative '../database/setup'
require_relative './fixtures'

require_relative '../cedar_api'
require 'minitest/autorun'
require 'rack/test'

require_relative '../util/cedar_logger'
CedarLogger.suppress_logging

module CedarApi
  module TestHelper
    def app
      Sinatra::Application
    end

    def datestring_to_datetime_range(datestring)
      case datestring
      when /^\d{4}$/ # YYYY
        start_date = DateTime.new(datestring.to_i, 1, 1)
        end_date = start_date.next_year - 1.seconds
        [start_date, end_date]
      when /^\d{4}-\d{2}$/ # YYYY-MM
        date_parts = datestring.split('-').map(&:to_i)
        start_date = DateTime.new(date_parts[0], date_parts[1], 1)
        end_date = start_date.next_month - 1.seconds
        [start_date, end_date]
      when /^\d{4}-\d{2}-\d{2}$/ # YYYY-MM-DD
        date_parts = datestring.split('-').map(&:to_i)
        start_date = DateTime.new(date_parts[0], date_parts[1], date_parts[2])
        end_date = start_date.next_day - 1.seconds
        [start_date, end_date]
      end
    end
  end
end
