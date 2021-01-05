# frozen_string_literal: true

require 'sinatra'
require 'json'

require_relative 'database/models'

get '/' do
  "Artifact count: #{Artifact.count}"
end

get '/:id' do |id|
  Artifact[id].to_json
end
