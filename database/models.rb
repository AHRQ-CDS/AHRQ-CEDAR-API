# frozen_string_literal: true

require_relative 'setup'

# Data models
class Artifact < Sequel::Model
  def to_fhir
    FHIRAdapter.parse_to_fhir(self)
  end
end
