# CEDAR

The Patient Protection and Affordable Care Act (ACA) of 2010 emphasized the importance of
patient-centered outcomes research (PCOR). The ACA mandated that the Agency for Healthcare Research
and Quality (AHRQ) invest in the dissemination of PCOR findings. AHRQ disseminates PCOR findings to
stakeholders and end users, including providers, health systems, patients, payers, and policymakers.
To facilitate this dissemination, AHRQ and its Center for Evidence and Practice Improvement (CEPI)
develop electronic means to transfer research findings, maintains publicly available databases of
government-funded scientific study data, and trains researchers in PCOR methods.

CEDAR (CEPI Evidence Discovery And Retrieval) is a standards-based application programming interface
(API) that supports search, access, and use of PCOR and other research findings across multiple
repositories within AHRQ CEPI. CEDAR makes access to all of these different resources in one place
possible by using health IT standards such as Health Level 7's Fast Healthcare Interoperability
Resources (FHIR) standard.

CEDAR enables health IT developers to integrate AHRQ CEPI research findings directly into their
existing systems, where the findings can then be accessed and used by researchers, clinicians,
policymakers, patients, and others.  CEDAR optimizes the use of PCOR and research data by following
standard guidelines for improving the Findability, Accessibility, Interoperability, and Reuse
([the FAIR principles](https://www.go-fair.org/fair-principles/))
of digital assets, providing fast and efficient access to information. The goal is to make it easy
to find the right data, at the right time, all in one place, directly from the systems that people
are already using.

CEDAR is intended to be publicly available for other platforms to use to discover and retrieve AHRQ
evidence from multiple resources simultaneously.

# The CEDAR API

The CEDAR Application Programming Interface (API) can be used to programmatically find and retrieve
information about the artifacts that CEDAR indexes. An API is a set of rules that describe how two
systems can communicate with each other. The CEDAR API allows developers to expand existing systems
or create new ones that interact with CEDAR and artifacts indexed by CEDAR. CEDAR was developed as
an API rather than as a website to promote flexibility in the types of use cases that CEDAR supports
as well as to allow CEDAR to be more easily integrated with existing systems.

The CEDAR API uses a RESTful approach. REST, or
[Representational State Transfer](http://www.ics.uci.edu/~fielding/pubs/dissertation/rest_arch_style.htm),
is an architectural style that is typically implemented using internet technologies like the
[Hypertext Transfer Protocol (HTTP)](https://datatracker.ietf.org/doc/html/rfc2616) and
[JavaScript Object Notation (JSON)](https://datatracker.ietf.org/doc/html/rfc8259).
REST offers a simple stateless request-response pattern that makes building applications straight forward.

The CEDAR API is built using the
[Fast Healthcare Interoperability Resources (FHIR)](http://hl7.org/fhir/) standard.
FHIR is a RESTful standard for the electronic exchange of healthcare information. FHIR's focus on
health data and its basis on internet standards make it a good fit for CEDAR's goal of improving
access to PCOR and other research findings. The fundamental building block for organizing data in
FHIR is the [Resource](https://www.hl7.org/fhir/resource.html). A FHIR Resource is just a
well-specified way to represent a single concept, like a Patient or a Condition. The CEDAR API uses
the [Citation](https://build.fhir.org/citation.html) resource to represent and share information
about indexed artifacts.

The CEDAR API works by accepting requests that specify the artifacts of interest and responding with
all matching artifacts as JSON FHIR Citations. The API supports several types of interaction:

* Searching by artifact text in the title or body of the artifact; CEDAR automatically includes synonyms when conducting searches by text
* Searching by artifact keyword as specified by the source repository
* Searching by concept; CEDAR maps artifact keywords to health concepts in vocabularies like [SNOMED-CT](http://snomed.info/sct) or [MeSH](http://terminology.hl7.org/CodeSystem/MSH) using the [UMLS Metathesaurus](https://www.nlm.nih.gov/research/umls/knowledge_sources/metathesaurus/index.html)
* Searching by date; CEDAR allows artifacts to be filtered by the date that CEDAR detects they have been modified
* Searching by artifact status; each artifact in CEDAR can have a status of `draft`, `active`, `unknown`, or `retired`
* Searching by artifact publisher; searches can be scoped by the artifact source repository
* Retrieving the full list of repositories indexed by CEDAR
* Navigating through the MeSH concept hierarchy tree to find relevant concepts for searching

You can find a complete guide to using the CEDAR API in the [CEDAR API Getting Started Guide](getting_started_guide.html).
The specification for the API can be found in the [CEDAR API Specification](swagger/).
