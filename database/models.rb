# frozen_string_literal: true

require_relative 'setup'

# Data models
class Artifact < Sequel::Model
  many_to_one :repository
end

class Repository < Sequel::Model
  one_to_many :artifacts
end

class Synonym < Sequel::Model
end
