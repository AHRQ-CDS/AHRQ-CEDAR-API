
RuleSet: Publisher
* publisher = "AHRQ CEDAR"
* contact.telecom.system = #url
* contact.telecom.value = "https://cds.ahrq.gov/cedar"

Instance: Citation-get-artifact-types
InstanceOf: OperationDefinition
Usage: #definition
* version = "0.1.0"
* name = "get-artifact-types"
* title = "Get Citation knowledge artifact types"
* status = #draft
* kind = #operation
* date = "2021-12-14"
* insert Publisher
* description = "Get all knowledge artifact types for Citation"
* code = #get-artifact-types
* resource = #Citation
* system = false
* type = true
* instance = false
* parameter.name = #artifact-type
* parameter.use = #out
* parameter.min = 0
* parameter.max = "*"
* parameter.documentation = "Coding for artifact types used by citedArtifact's classifier"
* parameter.type = #Coding

Instance: CodeSystem-get-mesh-children
InstanceOf: OperationDefinition
Usage: #definition
* version = "0.1.0"
* name = "get-mesh-children"
* title = "Get MeSH child concepts from MeSH Tree Number"
* status = #draft
* kind = #operation
* date = "2021-08-25"
* insert Publisher
* description = "Given a MeSH Tree Number, get MeSH child concepts"
* code = #get-mesh-children
* resource = #CodeSystem
* system = false
* type = true
* instance = false
* parameter[0].name = #code
* parameter[=].use = #in
* parameter[=].min = 0
* parameter[=].max = "1"
* parameter[=].documentation = "MESH Tree Number for parent concept. If the parameter is not provided, operation SHALL return the first level nodes in MeSH Tree."
* parameter[=].type = #code
* parameter[+].name = #concept
* parameter[=].use = #out
* parameter[=].min = 0
* parameter[=].max = "*"
* parameter[=].documentation = "Coding for child concepts. Each concept has an extension for the tree number of that concept, whether that concept has children and the number of artifacts directly or indirectly (via child concepts) associated with that concept. If the parent concept does not have any child, server SHALL return an empty array"
* parameter[=].type = #Coding