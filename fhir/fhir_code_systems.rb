# frozen_string_literal: true

module FHIRCodeSystems
  FHIR_CODE_SYSTEM_URLS = {
    'MTH' => 'http://www.nlm.nih.gov/research/umls/mth',
    'MSH' => 'http://terminology.hl7.org/CodeSystem/MSH',
    'MEDLINEPLUS' => 'http://www.nlm.nih.gov/research/umls/medlineplus',
    'SNOMEDCT_US' => 'http://snomed.info/sct',
    'SCTSPA' => 'http://snomed.info/sct/449081005',
    'MSHSPA' => 'http://www.nlm.nih.gov/research/umls/mshspa',
    'ICD10CM' => 'http://hl7.org/fhir/sid/icd-10-cm',
    'RXNORM' => 'http://www.nlm.nih.gov/research/umls/rxnorm'
  }.freeze
  QUALITY_OF_EVIDENCE_CODES = [
    {
      code: 'low',
      display: 'Low quality',
      sort_value: 0
    },
    {
      code: 'moderate',
      display: 'Moderate quality',
      sort_value: 1
    },
    {
      code: 'high',
      display: 'High quality',
      sort_value: 2
    }
  ].freeze
end
