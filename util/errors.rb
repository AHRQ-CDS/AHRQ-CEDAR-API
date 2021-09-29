# frozen_string_literal: true

# Parent class for errors need to converted to FHIR OperationOutcome
class FhirError < StandardError
  attr_accessor :code

  def to_operation_outcome_json
    oo = FHIR::OperationOutcome.new(
      issue: [
        {
          severity: 'error',
          code: code,
          details: {
            text: message
          }
        }
      ]
    )

    oo.to_json
  end
end

# Error for Invalid Parameter value
class InvalidParameterError < FhirError
  def initialize(parameter:, value: nil)
    message = "Search parameter #{parameter} has invalid value"
    message += " #{value}." if value.present?
    super(message)

    @code = 'value'
  end
end

# Error for Database connection
class DatabaseError < FhirError
  def initialize(message:)
    super(message)

    @code = 'exception'
  end
end
