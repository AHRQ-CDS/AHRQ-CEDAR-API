# Generating FHIR Artifacts

## Install Tools

```bash
gem install jekyll
npm install -g fsh-sushi
./_updatePublisher.sh
```

## Generate the Implementation Guide

```bash
./_genonce.sh
```

Note that you can also just run the initial Sushi compile via `sushi .` at development time. `./_genonce.sh` is needed to generate the complete FHIR `StructureDefinition` resources that include the `snapshot` in addition to the `differential` created by Sushi.

## Update the FHIR API Resources

```bash
cp output/StructureDefinition-extension-*.json ../resources
```
