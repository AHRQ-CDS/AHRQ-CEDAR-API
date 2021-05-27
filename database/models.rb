# frozen_string_literal: true

require_relative 'setup'

# Data models
class Artifact < Sequel::Model
  many_to_one :repository
  many_to_many :concepts
end

class Repository < Sequel::Model
  one_to_many :artifacts
end

class Concept < Sequel::Model
  many_to_many :artifacts
end
