# frozen_string_literal: true

require_relative 'setup'
require_relative '../fhir/citation'

# Data models
class Artifact < Sequel::Model
  many_to_one :repository
  many_to_many :concepts
  one_to_many :versions, key: :item_id, order: :id, conditions: { item_type: 'Artifact', event: 'update' }
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

# Data model for versions table
class Version < Sequel::Model
  many_to_one :artifacts

  def build_artifact
    Artifact.unrestrict_primary_key
    Artifact.new(object)
  end
end
