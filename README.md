# CEDAR API

## Background
CEDAR API is a backend service intended to allow a diverse set of existing or new systems to access the data that CEDAR aggregates from multiple source repositories. This approach allows CEDAR to support many different types of uses. For example, a clinician and a researcher may both find CEDAR valuable, but the way they would like to use CEDAR may be very different. So systems that accommodate to different user types like these could potentially benefit from a single API with access to, and handling for multiple data sources.

For more information, please see [Introduction](doc/Introduction.md) & [Getting Started](doc/GettingStarted.md)

## Prerequisites

- Ruby 2.7.4 or later
- Bundler
- Docker (if building Docker image)

## Installation and Setup for the Development Environment

This is a Ruby and Sinatra app. To install dependencies before running for the first time, run

```
bundle install
```

This application requires that the CEDAR Admin application has been setup and run at least once for underlying CEDAR data models and initial data imports. The CEDAR Admin application is not required to be running for CEDAR API to function.

To complete initial setup of CEDAR Admin, clone the CEDAR Admin repository. Follow the instructions on the CEDAR Admin README for any required dependencies specific to CEDAR Admin. (Particularly umls_concepts and mesh_concepts imports)

To run CEDAR API:
```
ruby cedar_api.rb
```

## Test

```sh
bundle exec rake
```
