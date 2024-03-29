Extension: StrengthOfRecommendation
Id: extension-strength-of-recommendation
Title: "Strength of Recommendation Extension"
Description: "Specifies the strength of recommendations contained within a cited artifact."
* . ^max = "1"
* ^context.type = #element
* ^context.expression = "Citation.citedArtifact"
* value[x] only CodeableConcept
* valueCodeableConcept 1..1
* valueCodeableConcept from http://hl7.org/fhir/ValueSet/certainty-rating (required)

Extension: QualityOfEvidence
Id: extension-quality-of-evidence
Title: "Quality of Evidence Extension"
Description: "Specifies the quality of evidence for a cited artifact."
* . ^max = "1"
* ^context.type = #element
* ^context.expression = "Citation.citedArtifact"
* value[x] only CodeableConcept
* valueCodeableConcept 1..1
* valueCodeableConcept from http://hl7.org/fhir/ValueSet/certainty-rating (required)

Extension: MeshConcept
Id: extension-mesh-concept
Title: "MeSH Concept Extension"
Description: "Specifies the MeSH concept that is the target of a search in a related link."
* . ^max = "1"
* ^context.type = #element
* ^context.expression = "Bundle.link"
* value[x] only CodeableConcept
* valueCodeableConcept 1..1
* valueCodeableConcept.coding.system = "https://www.nlm.nih.gov/mesh"

Extension: MeshTreeNumber
Id: extension-mesh-tree-number
Title: "Mesh Tree Number Extension"
Description: "A code for MeSH Tree Number"
* . ^max = "1"
* ^context.type = #element
* ^context.expression = "Coding"
* value[x] only code
* valueCode 1..1

Extension: MeshHasChildren
Id: extension-mesh-has-children
Title: "Mesh Has Children Extension"
Description: "Specifies whether the MeSH Tree node has children"
* . ^max = "1"
* ^context.type = #element
* ^context.expression = "Coding"
* value[x] only boolean
* valueBoolean 1..1

Extension: MeshDirectArtifactCount
Id: extension-mesh-direct-artifact-count
Title: "Mesh Direct Artifact Count Extension"
Description: "Specifies how many artifacts are directly associated with a MeSH concept"
* . ^max = "1"
* ^context.type = #element
* ^context.expression = "Coding"
* value[x] only unsignedInt
* valueUnsignedInt 1..1

Extension: MeshIndirectArtifactCount
Id: extension-mesh-indirect-artifact-count
Title: "Mesh Indirect Artifact Count Extension"
Description: "Specifies how many artifacts are indirectly associated with a MeSH concept"
* . ^max = "1"
* ^context.type = #element
* ^context.expression = "Coding"
* value[x] only unsignedInt
* valueUnsignedInt 1..1

Extension: OrganizationDescription
Id: extension-organization-description
Title: "Organization Description Extension"
Description: "Specifies the description text of an Organization"
* . ^max = "1"
* ^context.type = #element
* ^context.expression = "Organization"
* value[x] only string
* valueString 1..1

Extension: ContentSearchRank
Id: extension-content-search-rank
Title: "Rank of Content Search Extension"
Description: "Specifies the rank of citation within content search results."
* . ^max = "1"
* ^context.type = #element
* ^context.expression = "Bundle.entry"
* value[x] only decimal
* valueDecimal 1..1
