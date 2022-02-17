# Generating FHIR Artifacts

The [FHIR `StructureDefinition`](http://hl7.org/fhir/structuredefinition.html) resources used in the CEDAR API are generated from [FHIR Shorthand (FSH)](http://hl7.org/fhir/uv/shorthand/) source files. Instead of changing an extension by editing the corresponding file in the [`../resources`](../resources) directory, make changes to the files in [`input/fsh`](input/fsh) and follow the instructions below to update the generated files.

## Install Tools

```bash
gem install jekyll
npm install -g fsh-sushi
cd fsh
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
