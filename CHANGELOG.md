# Changelog

## v0.8.0 - 2023-03-14

* Tracks returned artifacts for each search

## v0.7.2 - 2023-02-22

* Adds support for returning numerical content rankings with search results
* Updates to Ruby 3.0.3, Sinatra 3.0.5, and Rails 6.1.7

## v0.7.1 - 2023-01-18

* Removes flagged and suppressed artifact versions from search results
* Fixes the base URL used in structure definitions and search results
* Adds copyright information on source repositories to results

## v0.7.0 - 2023-01-05

* Adds related search links to search results
* Fixes issues with handling punctuation and hyphens in free text searches
* Adds organization description to API results
* Updates C# example code
* Updates swagger documentation
* Completes move of documentation from API repository to static content repository
* Updates dependencies

## v0.6.0 - 2022-10-03

* Supports hyphens in title search
* Extends the CEDAR logger to support debug logging level
* Fixes issue where text search for exact title did not return matching item
* Updates synonym expansion to use database stemming
* Updates synonym handling to include phrase synonyms for simple queries
* Updates Swagger documentation

## v0.5.1 - 2022-07-13

* Updates API to return search results with a Bundle ID set to the search ID

## v0.5.0 - 2022-07-05

* Updates FHIR Citation resource to continue aligning with standard
* Adds support for retracted status for artifacts deleted from source repository
* Updates logging to record search result counts by repository
* Sets a default page size of 10 results
* Adds support for multiple ANDed title:contains searches
* Fixes bug in handling zero search results when searching by classification code
* Adds an API endpoint for returning search results in CSV format
* Adds new search parameters for quality of evidence and strength of recommendation
* Adds ability to specify the order of search results
* Fixes article-date:missing search to support negation
* Adds configurable support for tracking user clicks on artifact links
* Uses lowercase matching against concepts to expand search via synonyms
* Fixes issue with synonym searching on search terms with hyphens
* Adds contribution guide, code of conduct and terms and conditions
* Fixes sort ordering issue where free text search ranking was always the first sort criteria

## v0.4.0 - 2022-02-17

* Adds a useful default sort order
* Adds application level logging to stdout
* Adds a basic C# console application as an example CEDAR client

## v0.3.0 - 2022-01-05

* Updates search logging to store date in UTC
* Adds the article-date search parameter
* Adds a _history endpoint to Citation
* Adds a $get-artifact-types endpoint
* Adds the artifact-type search parameter

## v0.2.0 - 2022-11-03

* Adds a getting started guide and introductory text
* Updates swagger documentation
* Supports multiple-and concept search
* Makes minor fixes to FHIR resource definitions
* Adds the alias element on the FHIR Organization resource
* Makes security improvements to prevent arbitrary file access

## v0.1.0 - 2022-10-13

* Initial version of CEDAR API
