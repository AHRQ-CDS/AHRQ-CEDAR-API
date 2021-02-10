# frozen_string_literal: true

require 'sequel'
require 'json'
require 'yaml'
require 'erb'

# Load YAML database config file in this directory (interpreting any ERB)
env = settings.environment.to_s || 'development'
config = YAML.safe_load(ERB.new(File.read('database/config.yml')).result)
database_config = config[env]

# Connect to the specified database
DB = Sequel.connect(database_config)

# Add JSON output capability to all models
Sequel::Model.plugin :json_serializer
