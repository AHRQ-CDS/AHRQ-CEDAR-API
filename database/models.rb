# frozen_string_literal: true

require_relative 'setup'

# Data models
class Artifact < Sequel::Model
  many_to_one :repository
  many_to_many :concepts
  one_to_many :versions, key: :item_id, order: :id
end

class Repository < Sequel::Model
  one_to_many :artifacts
end

class Concept < Sequel::Model
  many_to_many :artifacts
end

class SearchLog < Sequel::Model
  one_to_many :search_parameter_logs
  # Add Timestamps to automatically populate created_at and updated_at columns
  plugin :timestamps, update_on_create: true
end

class SearchParameterLog < Sequel::Model
  many_to_one :search_log
end

class MeshTreeNode < Sequel::Model
  many_to_one :parent, class: self
  one_to_many :children, key: :parent_id, order: :name, class: self
end

class Version < Sequel::Model
  many_to_one :artifacts, key: :item_id
end
