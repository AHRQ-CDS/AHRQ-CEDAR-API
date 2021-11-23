# CEDAR API

## Background
CEDAR API is a backend service intended to allow a diverse set of existing or new systems to access the data that CEDAR aggregates from multiple source repositories. This approach allows CEDAR to support many different types of uses. For example, a clinician and a researcher may both find CEDAR valuable, but the way they would like to use CEDAR may be very different. So systems that accommodate to different user types like these could potentially benefit from a single API with access to, and handling for multiple data sources.

For more information, please see [Introduction](doc/Introduction.md) & [Getting Started](doc/GettingStarted.md)

## Prerequisites

- Ruby 2.7.4 or later
- Bundler
- Docker (if building Docker image)

## Install

Clone this repository, then:

```sh
cd cedar_api
bundle install
```

## Test

```sh
bundle exec rake
```
