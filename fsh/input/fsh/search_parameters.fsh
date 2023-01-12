Instance: cedar-citation-article-date
InstanceOf: SearchParameter
Usage: #definition
* version = "0.1.0"
* name = "CedarCitationArticleDate"
* status = #active
* experimental = false
* code = #article-date
* base = #Citation
* description = "Publishing date of the cited artifact"
* type = #date
* expression = "Citation.citedArtifact.publicationForm.articleDate"
* comparator[0] = #eq
* comparator[+] = #ne
* comparator[+] = #gt
* comparator[+] = #lt
* comparator[+] = #ge
* comparator[+] = #le
* comparator[+] = #sa
* comparator[+] = #eb
* comparator[+] = #ap
* modifier = #missing

Instance: cedar-citation-artifact-current-state
InstanceOf: SearchParameter
Usage: #definition
* version = "0.1.0"
* name = "CedarCitationArtifactCurrentState"
* status = #active
* experimental = false
* code = #artifact-current-state
* base = #Citation
* description = "Current state of the cited artifact"
* type = #token
* expression = "Citation.citedArtifact.currentState"

Instance: cedar-citation-artifact-publisher
InstanceOf: SearchParameter
Usage: #definition
* version = "0.1.0"
* name = "CedarCitationArtifactPublisher"
* status = #active
* experimental = false
* code = #artifact-publisher
* base = #Citation
* description = "Publisher of the cited artifact"
* type = #string
* expression = "Citation.citedArtifact.publicationForm.publishedIn.publisher.display"

Instance: cedar-citation-artifact-type
InstanceOf: SearchParameter
Usage: #definition
* version = "0.1.0"
* name = "CedarCitationArtifactType"
* status = #active
* experimental = false
* code = #artifact-type
* base = #Citation
* description = "Type of the cited artifact"
* type = #string
* expression = "Citation.citedArtifact.classification.where(type.coding.code = 'knowledge-artifact-type').classifier"

Instance: cedar-citation-classification
InstanceOf: SearchParameter
Usage: #definition
* version = "0.1.0"
* name = "CedarCitationClassification"
* status = #active
* experimental = false
* code = #classification
* base = #Citation
* description = "Classification of the citation"
* type = #token
* expression = "Citation.citedArtifact.classification.classifier"
* multipleOr = true
* multipleAnd = true
* modifier = #text

Instance: cedar-citation-quality-of-evidence
InstanceOf: SearchParameter
Usage: #definition
* version = "0.1.0"
* name = "CedarCitationQualityOfEvidence"
* status = #active
* experimental = false
* code = #quality-of-evidence
* base = #Citation
* description = "Quality of evidence included in the citation"
* type = #token
* expression = "Citation.citedArtifact.extension.where(url='https://cds.ahrq.gov/cedar/api/fhir/StructureDefinition/extension-quality-of-evidence')"
* multipleOr = true
* modifier = #missing

Instance: cedar-citation-strength-of-recommendation
InstanceOf: SearchParameter
Usage: #definition
* version = "0.1.0"
* name = "CedarCitationStrengthOfRecommendation"
* status = #active
* experimental = false
* code = #strength-of-recommendation
* base = #Citation
* description = "Strength of recommendations included in the citation"
* type = #token
* expression = "Citation.citedArtifact.extension.where(url='https://cds.ahrq.gov/cedar/api/fhir/StructureDefinition/extension-strength-of-recommendation')"
* multipleOr = true
* modifier = #missing

Instance: cedar-citation-title
InstanceOf: SearchParameter
Usage: #definition
* version = "0.1.0"
* name = "CedarCitationTitle"
* derivedFrom = "http://hl7.org/fhir/SearchParameter/Citation-title"
* status = #active
* experimental = false
* code = #title
* base = #Citation
* description = "The human-friendly name of the citation"
* type = #string
* expression = "Citation.title"
* multipleOr = true
* modifier = #contains