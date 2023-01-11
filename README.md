# The CEDAR Project

The [CEDAR project](https://cds.ahrq.gov/cedar/) provides a standards-based API that supports search, access, and use of patient centered outcomes research and other research findings across multiple repositories and programs within [AHRQ's Center for Evidence and Practice Improvement (CEPI)](https://www.ahrq.gov/cpi/centers/cepi/index.html).

Health IT developers can use CEDAR to integrate AHRQ CEPI research findings directly into their existing systems, where the findings can then be accessed and used by researchers, clinicians, policymakers, patients, and others. CEDAR optimizes the use of patient centered outcomes research and other research data by following standard guidelines for improving the Findability, Accessibility, Interoperability, and Reuse (the FAIR principles) of digital assets, providing fast and efficient access to information.

CEDAR is publicly available for other platforms to use to discover and retrieve AHRQ evidence from multiple resources simultaneously.

## CEDAR API

### Background

CEDAR API is a backend service intended to allow a diverse set of existing or new systems to access
the data that CEDAR aggregates from multiple source repositories. This approach allows CEDAR to
support many different types of uses. For example, a clinician and a researcher may both find CEDAR
valuable, but the way they would like to use CEDAR may be very different. So systems that
accommodate to different user types like these could potentially benefit from a single API with
access to, and handling for multiple data sources.

For more information, please see:

- [Introduction](doc/Introduction.md)
- [Getting Started](doc/GettingStarted.md)
- [Contribution Guide](CONTRIBUTING.md)
- [Code of Conduct](CODE-OF-CONDUCT.md)
- [Terms and Conditions](TERMS-AND-CONDITIONS.md)

### Prerequisites

- Ruby 2.7.4 or later
- Bundler
- Docker (if building Docker image)

### Installation and Setup for the Development Environment

This is a Ruby and Sinatra app. To install dependencies before running for the first time, run

```
bundle install
```

This application requires that the CEDAR Admin application has been setup and run at least once for
underlying CEDAR data models and initial data imports. The CEDAR Admin application is not required
to be running for CEDAR API to function.

To complete initial setup of CEDAR Admin, clone the CEDAR Admin repository. Follow the instructions
on the CEDAR Admin README for any required dependencies specific to CEDAR Admin, particularly for
the umls_concepts and mesh_concepts imports.

To run CEDAR API:

```
ruby cedar_api.rb
```

### Testing

```
bundle exec rake
```

### Configuration Options

The following environment variables can be used to configure the function of CEDAR API

- __`ARTIFACT_URL_CLICK_LOGGING`__ When the value is `true`, the value of the FHIR `Citation.citedArtifact.webLocation.url` returned in searches will be a CEDAR API url that will redirect to the indexed artifact. This allows CEDAR API to track when artifacts that are returned by a search are visited in a browser.
- __`CEDAR_API_PATH_PREFIX`__ Supports deployment of CEDAR API behind a reverse proxy like nginx when the path to CEDAR API is something other than `/`. E.g. if CEDAR API is deployed at `/api`, set `CEDAR_API_PATH_PREFIX=api`.
- __`HOSTNAME`__ Specifies the URL that will be used for FHIR `Citation.identifier.system` and `Citation.contact.telecom.value` generated by CEDAR API. Defaults to `https://cds.ahrq.gov/cedar/api/fhir` if not specified.

### FHIR Definitions

Read [Generating FHIR Artifacts](fsh/README.md) before making changes to the [FHIR `StructureDefinition`](http://hl7.org/fhir/structuredefinition.html) resources in the [`resources`](resources) directory.

## LICENSE

Copyright 2022 Agency for Healthcare Research and Quality.

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this software except
in compliance with the License. You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is
distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
implied.  See the License for the specific language governing permissions and limitations under the
License.
