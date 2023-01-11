# frozen_string_literal: true

require_relative 'setup'
require_relative '../fhir/citation'

# Data models
class Artifact < Sequel::Model
  many_to_one :repository
  many_to_many :concepts
  one_to_many :versions, key: :item_id, order: :id, conditions: { item_type: 'Artifact', event: 'update' }

  # A single import run can result in multiple versions of an artifact if flagged for administrator
  # attention. We don't want to expose all of these versions to API consumers, just the actual
  # approved version history.
  def public_version_history
    # Group the updates by import run and drop any that are the result of suppressed or flagged runs
    versions_by_import = versions.group_by(&:import_run_id)
    versions_by_import.reject! do |_import_id, import_versions|
      %w[suppressed flagged].include? import_versions.first.import_run.status
    end
    # Return the final version within each remaining import run
    versions_by_import.values.map(&:last).sort_by(&:id)
  end
end

class Repository < Sequel::Model
  one_to_many :artifacts
end

class Concept < Sequel::Model
  many_to_many :artifacts
end

class SearchLog < Sequel::Model
  # Add Timestamps to automatically populate created_at and updated_at columns
  plugin :timestamps, update_on_create: true
end

class MeshTreeNode < Sequel::Model
  many_to_one :parent, class: self
  one_to_many :children, key: :parent_id, order: :name, class: self
end

# Data model for versions table
class Version < Sequel::Model
  many_to_one :artifact
  many_to_one :import_run

  def build_artifact
    Artifact.unrestrict_primary_key
    Artifact.new(object)
  end
end

# Data model for import_runs table
class ImportRun < Sequel::Model
  one_to_many :versions, key: :import_run_id, order: :id
end
