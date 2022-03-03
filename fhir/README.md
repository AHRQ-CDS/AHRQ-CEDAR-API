To generate Citation class from FHIR StructureDefinition

1. Get Ruby FHIR Model build tool 
   * Clone fhir_model repo from https://github.com/fhir-crucible/fhir_models
2. Prepare FHIR spec
   * Download the latest FHIR spec from http://hl7.org/fhir/5.0.0-snapshot1/fhir-spec.zip
     * Unzip zip file
     * Copy site\profiles-resources.json to fhir_models/lib/fhir_models/definitions/structures/profile-resources.json
   * If FHIR spec download is not available (possible for latest CI build)
     * Download NPM package from http://hl7.org/fhir/5.0.0-snapshot1/hl7.fhir.r5.core.tgz
     * Unzip tgz file
     * Find StructureDefinition-Citation.json
     * Copy content to the Bundle entry for Citation in fhir_models/lib/fhir_models/definitions/structures/profile-resources.json
3. Generate Ruby class
   * Run command `bundle exec rake fhir:generate`
   * Copy generated Citation.rb to this folder