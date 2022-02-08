# Generating FHIR Artifacts

## Install Tools

```bash
npm install -g fsh-sushi
./_updatePublisher.sh
```

## Generate the Implementation Guide

```bash
sushi .
./_genonce.sh
```

## Update the FHIR API Resources

```bash
cp output/StructureDefinition-extension-*.json ../resources
```
