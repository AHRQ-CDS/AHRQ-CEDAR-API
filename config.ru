# frozen_string_literal: true

#\ -p 4567 # rubocop:disable Layout/LeadingCommentSpace:
require './cedar_api'

if ENV['CEDAR_API_PATH_PREFIX'].nil?
  run Sinatra::Application
else
  map("/#{ENV['CEDAR_API_PATH_PREFIX']}") { run Sinatra::Application }
end
