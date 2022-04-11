# Getting Started with the CEDAR API

## Introduction

The CEDAR API (the API for short) provides a standards-based unified search mechanism for the following repositories of Patient-Centered Outcomes Research (PCOR) artifacts:

- [Effective Healthcare Program (EHC)](https://effectivehealthcare.ahrq.gov)
- [Evidence-Based Practice Center (EPC)](https://www.ahrq.gov/research/findings/evidence-based-reports/overview/index.html)
- [United States Preventive Services Task Force (USPSTF)](https://www.uspreventiveservicestaskforce.org/uspstf/)
- [Systematic Review Data Repository (SRDR)](https://srdrplus.ahrq.gov)
- [CDS Connect](https://cds.ahrq.gov/cdsconnect)

This document explains how to use CEDAR API to search for PCOR artifacts using a variety of criteria. It also provides links and information about the standards used by the CEDAR API and provides hints and tips for effective use of the API.

### Intended Audience

This document is aimed at software developers intending to write code that interacts with the API. Some familiarity with the [Hypertext Transfer Protocol (HTTP)](https://datatracker.ietf.org/doc/html/rfc2616), [Uniform Resource Locators (URLs)](https://datatracker.ietf.org/doc/html/rfc3986) and [JavaScript Object Notation (JSON)](https://datatracker.ietf.org/doc/html/rfc8259) is assumed.

## Example Code

A simple [demonstration C# console application](c_sharp_example.html) that uses the CEDAR API is available as an example of API usage.

## API Usage

The API is used via the simple HTTP request+response pattern. All API requests are read-only, use the HTTP `GET` method, and each request is standalone and idempotent.

### Sample Request

For the first example we will search for PCOR artifacts related to hypertension. Copy the following URL into a browser or [click this link](https://cedar.ahrqdev.org/api/fhir/Citation?artifact-current-state=active&title:contains=hypertension&_count=10)

```text
https://cedar.ahrqdev.org/api/fhir/Citation?artifact-current-state=active&title:contains=hypertension&_count=10
```

Your browser will display several pages of JSON formatted data but, before we examine that, let's break down the URL into its component parts:

- `https://cedar.ahrqdev.org` is the server address
- `/api` is the root path of all API requests
- `/fhir` is the sub path for all API requests that use the [FHIR standard](http://hl7.org/fhir/)
- `/Citation` identifies the type of [FHIR resource](http://hl7.org/fhir/2021May/resourcelist.html) being accessed, in this case [`Citation`](http://hl7.org/fhir/2021May/citation.html)
- Following these components are several URL query parameters that represent [FHIR search parameters](https://www.hl7.org/fhir/search.html):
    - `artifact-current-state` with a value of `active` ensures that only artifacts that are currently active (i.e. not archived or superseded) will be included in the returned results
    - `title:contains` with a value of `hypertension` will search for artifacts whose title contains "hypertension" or a synonym of hypertension
    - `_count` with a value of `10` limits the search to include only the first 10 matching results

### Swagger / Open API

While learning the API, an alternative to manually creating the above URL (or writing code to do so) is to use the [interactive CEDAR Swagger](https://cedar.ahrqdev.org/swagger/#/) API description:

1. Visit the link above in a web browser
2. Locate the "Citation" section near the top of the page
3. Click the down arrow at the right of the "GET /Citation" line
4. Click the "Try it out" button at the top right of the box
5. Enter "hypertension" in the "title:contains" field
6. Enter "10" in the "_count" field
7. Click the "Execute" button

The result will show the API request URL that was created, an example of requesting that URL using the [`curl`](https://man7.org/linux/man-pages/man1/curl.1.html) command line tool, and the actual data returned by the API as JSON.

The Swagger page provides a convenient interactive tool for exploring the API, creating requests, and viewing sample responses.

### Sample Response

The API returns data in [FHIR JSON](https://www.hl7.org/fhir/json.html) format. Search results are returned as a [FHIR Bundle](https://www.hl7.org/fhir/bundle.html) of type [`searchset`](https://www.hl7.org/fhir/codesystem-bundle-type.html#bundle-type-searchset). Each entry in the search result bundle is a [FHIR Citation](http://hl7.org/fhir/2021May/citation.html) resource that contains metadata about a PCOR artifact. The following fields of each `Citation` resource are typically populated:

- `id` - a CEDAR-assigned unique identifier for the citation
- `url` - the API URL that can be used to retrieve the citation individually rather than as part of a search result bundle
- `title` - the title of the artifact
- `status` - the status of the citation
- `date` - the date the artifact was last updated in CEDAR
- `citedArtifact.identifier` - a PCOR repository-assigned identifier for the artifact
- `citedArtifact.dateAccessed` - the date the artifact was last updated in CEDAR
- `citedArtifact.currentState` - the status of the cited artifact
- `citedArtifact.title` - the title of the cited artifact
- `citedArtifact.abstract` - the description of the cited artifact
- `citedArtifact.webLocation` - the URL of the cited artifact in the source repository
- `citedArtifact.classification` - the type of artifact, keywords and concepts that classify the cited artifact

Cited artifacts have separate keyword and concept classifiers. Note that keyword classifiers are assigned by the PCOR repository while concepts are assigned by CEDAR; see "Searching By Concept" below for further details.

The [FHIR Citation](http://hl7.org/fhir/2021May/citation.html) definition documents the complete structure; that information is not repeated here for the sake of brevity.

### Search Result Paging

As shown in the first example, the [`_count`](https://www.hl7.org/fhir/search.html#count) search parameter controls the number of results returned. Searches can return a large number of results so it is good practice to use this parameter to limit the size of the results. A companion search parameter, `page`, defines the starting point for the returned result. Together, these two parameters can be used to page through a large search result list. E.g., a combination of `_count=10` and `page=1` would return the first 10 results while `_count=10` and `page=2` would return results 11-20 inclusive.

Conveniently, the API also includes links in the returned `Bundle.link` element to make paging through a result list easy. Below is the set of paging links from the example above:

```json
"total": 12,
"link": [
  {
    "relation": "self",
    "url": "http://cedar.ahrqdev.org/fhir/Citation?_count=10&artifact-current-state=active&page=1&title:contains=hypertension"
  },
  {
    "relation": "first",
    "url": "http://cedar.ahrqdev.org/fhir/Citation?_count=10&artifact-current-state=active&page=1&title:contains=hypertension"
  },
  {
    "relation": "last",
    "url": "http://cedar.ahrqdev.org/fhir/Citation?_count=10&artifact-current-state=active&page=2&title:contains=hypertension"
  },
  {
    "relation": "next",
    "url": "http://cedar.ahrqdev.org/fhir/Citation?_count=10&artifact-current-state=active&page=2&title:contains=hypertension"
  }
]
```

In the above, you can see that there are 12 matching results total, a link to the current page of results (`self`), a link to the first page of results (`first`), a link to the final page of results (`last`), and a link to the next page of results (`next`). These links can be used in applications to provide user-driven paging through large result sets.

### Searching By Artifact Text

The API offers three text search parameters:

1. `title` - search for artifacts whose title starts with (one of) the supplied value(s). The search is case insensitive. Multiple values should be separated using commas. E.g., `title=hypertension` would search for artifacts whose title starts with "hypertension" while `title=hypertension,hypotension` would search for artifacts whose title starts with _either_ "hypertension" or "hypotension".

2. `title:contains` - search for artifacts whose title includes (one of) the supplied value(s). Like `title`, the search is case insensitive and multiple values are separated by commas.

3. `_content` - free text search of artifact titles and descriptions with support for logical combinations of search terms and synonyms. E.g., `_content=((hypertension OR hypotension) AND afib)` would search the text of artifacts for those that include "hypertension" and "afib" or those that include "hypotension" and "afib". The following logical operators are supported: `AND`, `OR`, and `NOT`. Search terms can be quoted and this will result in searches that looks for artifacts that contain the quoted words close together in their text. E.g., `_content="atrial fibrillation"` would search for artifacts where "atrial" and "fibrillation" appear close together in the text of the title or description.

#### Synonym Support

CEDAR uses the [Unified Medical Language System (UMLS)](https://www.nlm.nih.gov/research/umls/index.html) to provide support for synonyms. Search terms sent in API requests are automatically expanded to a set of synonyms that are then used in queries. E.g., `_content=afib` would match artifacts that contain "afib", "af", "atrial fibrillation" or "auricular fibrillation" in their titles or descriptions.

The following search parameters support synonyms:

- Free text search using the `_content` API parameter (see above)
- Keyword search using the `_classification:text` API parameter (see below)

### Searching By Keyword

Searching by artifact keyword uses the `classification:text` search paramater. Searching by artifact keyword is similar to the `_content` search described above. The same logical operators and synonyms are supported. E.g., `classification:text=(afib OR "atrial flutter")` would search for artifacts with any of the following keywords: "afib", "af", "atrial fibrillation", "auricular fibrillation", "atrial flutter".

### Searching By Concept

CEDAR uses artifact keywords to identify related concepts via the UMLS. E.g., if an artifact has "hypertension" as a keyword, CEDAR would associate that artifact with [MeSH D006973 (Blood Pressure, High)](https://meshb.nlm.nih.gov/record/ui?ui=D006973) and [SNOMED-CT 38341003 (Hypertensive disorder)](https://browser.ihtsdotools.org/?perspective=full&conceptId1=38341003&edition=MAIN/SNOMEDCT-US/2021-09-01&release=&languages=en). The API supports search by concept using the following code systems:

- SNOMED-CT (`http://snomed.info/sct`)
- MeSH (`http://terminology.hl7.org/CodeSystem/MSH`)
- Medline Plus (`http://www.nlm.nih.gov/research/umls/medlineplus`)
- SNOMED-CT (ESP) (`http://snomed.info/sct/449081005`)
- MeSH (ESP) (`http://www.nlm.nih.gov/research/umls/mshspa`)
- ICD-10-CM (`http://hl7.org/fhir/sid/icd-10-cm`)
- RxNorm (`http://www.nlm.nih.gov/research/umls/rxnorm`)

Searching by artifact concept uses the `classification` search paramater. E.g., `classification=http://terminology.hl7.org/CodeSystem/MSH|D006973` would search for artifacts associated with [MeSH D006973 (Blood Pressure, High)](https://meshb.nlm.nih.gov/record/ui?ui=D006973). Note that the code system URI precedes the concept code separated by "|" as per the [FHIR token search](https://www.hl7.org/fhir/search.html#token) specification.

The code system URI prefix and "|" separator are optional. The earlier example could instead be written as `classification=D006973`. However, this would match the code `D006973` in any of the above code systems and this could result in unexpected results when a given code is present in multiple code systems with different meanings. For this reason, it is recommended that the code system URI is always used in concept search requests.

#### MeSH Browser

The API also offers the ability to browse the [MeSH concept hierarchy](https://meshb.nlm.nih.gov/treeView). This can be useful for constructing a user interface that provides direct search by MeSH concept.

Access to the MeSH concept hierarchy is via a [custom FHIR operation](https://www.hl7.org/fhir/operations.html) `get-mesh-children` available at the following [URL](https://cedar.ahrqdev.org/api/fhir/CodeSystem/$get-mesh-children):

```text
https://cedar.ahrqdev.org/api/fhir/CodeSystem/$get-mesh-children
```

An HTTP `GET` on the above URL will yield a [FHIR Parameters](https://www.hl7.org/fhir/parameters.html) resource that contains a list of the top level MeSH concepts, one of which is shown below:

```json
{
  "name": "concept",
  "valueCoding": {
    "extension": [
      {
        "url": "http://cedar.arhq.gov/StructureDefinition/extension-mesh-tree-number",
        "valueCode": "E"
      },
      {
        "url": "http://cedar.arhq.gov/StructureDefinition/extension-mesh-has-children",
        "valueBoolean": true
      },
      {
        "url": "http://cedar.arhq.gov/StructureDefinition/extension-mesh-direct-artifact-count",
        "valueUnsignedInt": 0
      },
      {
        "url": "http://cedar.arhq.gov/StructureDefinition/extension-mesh-indirect-artifact-count",
        "valueUnsignedInt": 1340
      }
    ],
    "system": "http://terminology.hl7.org/CodeSystem/MSH",
    "display": "Analytical, Diagnostic and Therapeutic Techniques, and Equipment"
  }
}
```

In the above representation:

- `display` provides the name of the concept ("Analytical, Diagnostic and Therapeutic Techniques, and Equipment").
- The `extension` with `url` ending with `extension-mesh-tree-number` provides the MeSH tree number of the concept ("E").
- The `extension` with `url` ending with `extension-mesh-has-children` indicates whether the concept has child concepts (true in this case).
- The `extension` with `url` ending with `extension-mesh-direct-artifact-count` provides the number of artifacts in CEDAR that are associated with this concept (0 in this case).
- The `extension` with `url` ending with `extension-mesh-indirect-artifact-count` provides the number of artifacts in CEDAR that are associated with descendents of this concept (1340 in this case).

To obtain the immediate children of a concept, issue a HTTP `GET` against the above URL and supply the tree number as the value of a `code` search parameter. E.g., to obtain the children of the concept illustrated above with tree number "E", the [URL](https://cedar.ahrqdev.org/api/fhir/CodeSystem/$get-mesh-children?code=E) would be:

```text
https://cedar.ahrqdev.org/api/fhir/CodeSystem/$get-mesh-children?code=E
```

The resulting list is formatted the same as the top level concept list as shown above, e.g.:

```json
{
  "name": "concept",
  "valueCoding": {
    "extension": [
      {
        "url": "http://cedar.arhq.gov/StructureDefinition/extension-mesh-tree-number",
        "valueCode": "E01"
      },
      {
        "url": "http://cedar.arhq.gov/StructureDefinition/extension-mesh-has-children",
        "valueBoolean": true
      },
      {
        "url": "http://cedar.arhq.gov/StructureDefinition/extension-mesh-direct-artifact-count",
        "valueUnsignedInt": 127
      },
      {
        "url": "http://cedar.arhq.gov/StructureDefinition/extension-mesh-indirect-artifact-count",
        "valueUnsignedInt": 273
      }
    ],
    "system": "http://terminology.hl7.org/CodeSystem/MSH",
    "code": "D003933",
    "display": "Diagnosis"
  }
}
```

The `system` and `code` values (note `D003933` _not_ the tree number `E01`) can be used in a concept search to retrieve a list of artifacts associated with that MeSH concept:  `classification=http://terminology.hl7.org/CodeSystem/MSH|D003933`. See above for additional details on searching by concept.

### Searching By Date

The API supports search by last modification date using the [`FHIR _lastUpdated` search parameter](https://www.hl7.org/fhir/search.html#lastUpdated). E.g., `_lastUpdated=gt2021-10-26` would match any artifact updated after 10/26/2021. Note that the last modification date is the date that CEDAR last noted a change in an artifact (e.g., change in title text, description, keywords etc) - this may be different from the artifact publication date.

Dates can be specified with granularities of a day (formatted as YYYY-MM-DD), a month (formatted as YYYY-MM) or a year (formatted as YYYY). In all cases the date represents a range that encompasses the start of the specified period and the end of the specified period. E.g., "2021" represents any time that is both on or after midnight on 12/31/2020 and before midnight on 12/31/2021.

Dates can be compared using a variety of operators (e.g., `gt` in the above example); the full list is specified by the [FHIR search specification](https://www.hl7.org/fhir/search.html#prefix). Also see [how each operator works with dates](https://www.hl7.org/fhir/search.html#date).

### Searching By Artifact Status

Each artifact in CEDAR has a status of:

- `draft`: the artifact is a draft or other non-final form
- `active`: the artifact is current
- `unknown`: the artifact's status could not be determined
- `retired`: the artifact is no longer current

The API supports searching by artifact status using the `artifact-current-state` search parameter. E.g., `artifact-current-state=active` selects artifacts known to be current. Multiple status values, separated by a comma, can be specified, e.g., `artifact-current-state=active,unknown` would select artifacts known to be current or whose status could not be determined.

Note that at least one artifact status is required for every search.

### Searching By Artifact Publisher

As described earlier, CEDAR indexes external repositories of PCOR artifacts. Searches can be scoped to one or more repositories using the `artifact-publisher` search parameter. E.g., `artifact-publisher=ehc,epc` would select artifacts from the [Effective Healthcare Program](https://effectivehealthcare.ahrq.gov) and [Evidence-Based Practice Center](https://www.ahrq.gov/research/findings/evidence-based-reports/overview/index.html) repositories.

#### Repository List

The full list of repositories supported by CEDAR can be obtained from the following [URL](https://cedar.ahrqdev.org/api/fhir/Organization):

```text
https://cedar.ahrqdev.org/api/fhir/Organization
```

Results are returned as a [FHIR Bundle](https://www.hl7.org/fhir/bundle.html) of type [`searchset`](https://www.hl7.org/fhir/codesystem-bundle-type.html#bundle-type-searchset). Each entry in the search result bundle is a [FHIR Organization](https://www.hl7.org/fhir/organization.html). The identifier used as the value of the `artifact-publisher` search parameter is the value of the `Organization.id`.

Supported repositories and their identifiers include:

- `ehc` - [Effective Healthcare Program](https://effectivehealthcare.ahrq.gov)
- `epc` - [Evidence-Based Practice Center](https://www.ahrq.gov/research/findings/evidence-based-reports/overview/index.html)
- `uspstf` - [United States Preventive Services Task Force](https://www.uspreventiveservicestaskforce.org/uspstf/)
- `srdr` - [Systematic Review Data Repository](https://srdrplus.ahrq.gov)
- `cds-connect` - [CDS Connect](https://cds.ahrq.gov/cdsconnect)

## Additional FHIR Resources

The API also makes available a number of FHIR resources that describe its capabilities:

- [`metadata`](https://cedar.ahrqdev.org/api/fhir/metadata) is the [FHIR `CapabilityStatement`](https://www.hl7.org/fhir/capabilitystatement.html) that includes links to custom [FHIR `SearchParameter`](https://www.hl7.org/fhir/searchparameter.html) and [FHIR `OperationDefinition`](https://www.hl7.org/fhir/operationdefinition.html) resources:
    - [`SearchParameter/cedar-citation-classification`](http://cedar.ahrqdev.org/api/fhir/SearchParameter/cedar-citation-classification): search by concept
    - [`SearchParameter/cedar-citation-artifact-current-state`](http://cedar.ahrqdev.org/api/fhir/SearchParameter/cedar-citation-artifact-current-state): search by artifact status
    - [`SearchParameter/cedar-citation-artifact-publisher`](http://cedar.ahrqdev.org/api/fhir/SearchParameter/cedar-citation-artifact-publisher): search by artifact
    - [`SearchParameter/cedar-citation-title`](http://cedar.ahrqdev.org/api/fhir/SearchParameter/cedar-citation-title): search by artifact title
    - [`OperationDefinition/CodeSystem-get-mesh-children`](http://cedar.ahrqdev.org/api/fhir/OperationDefinition/CodeSystem-get-mesh-children): for browsing the MeSH concept hierarchy

As illustrated earlier, the [`CodeSystem/$get-mesh-children`](http://cedar.ahrqdev.org/api/fhir/OperationDefinition/CodeSystem-get-mesh-children) operation utilizes four extensions to capture additional metadata about each MeSH concept. The formal definition of these extensions are as follows:

- [`StructureDefinition/extension-mesh-direct-artifact-count`](http://cedar.ahrqdev.org/api/fhir/StructureDefinition/extension-mesh-direct-artifact-count): an extension to hold the count of artifact directly associated with a concept
- [`StructureDefinition/extension-mesh-indirect-artifact-count`](http://cedar.ahrqdev.org/api/fhir/StructureDefinition/extension-mesh-indirect-artifact-count): an extension to hold the count of artifact indirectly associated with a concept
- [`StructureDefinition/extension-mesh-has-children`](http://cedar.ahrqdev.org/api/fhir/StructureDefinition/extension-mesh-has-children): an extension to indicate whether a MeSH concept has child concepts

- [`StructureDefinition/extension-mesh-tree-number`](http://cedar.ahrqdev.org/api/fhir/StructureDefinition/extension-mesh-tree-number): an extension to hold the MeSH tree number

## Comma-Separated Values (CSV) Download

In addition to the FHIR API operation, the CEDAR API also offers the ability to download search results as a comma-separated values (CSV) file. The CSV download operation offers all of the same search parameters that are supported for the FHIR `Citation` search operation, only the URL path differs. Below is a sample request to the CSV endpoint:

```text
https://cedar.ahrqdev.org/api/csv?artifact-current-state=active&title:contains=hypertension
```

Note that paging of results via the `page` and `_count` parameters is not supported for CSV.
