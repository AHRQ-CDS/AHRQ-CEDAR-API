# CEDAR C# Client Example
This is a basic .NET console application that demonstrates usage of the
[CEDAR API](https://cedar.ahrqdev.org/) as well as interoperability supported
by the [FHIR standard](https://www.hl7.org/fhir/). CEDAR API features you can see
in action include:
- Basic resource retrieval
- Text search support
- Keyword search support
- Text search with additional filtering parameter(s) support
- FHIR Data Serialization & Deserialization (parsing) via 
[firely-net-sdk FHIR SDK](https://github.com/FirelyTeam/firely-net-sdk/tree/develop-r5)

## Prerequisites

- [.NET](https://docs.microsoft.com/en-us/dotnet/core/install/) 6.0 or later

## Dependencies

This example was built using the following libraries and versions:

- [DotNetEnv Version 2.3.0](https://www.nuget.org/packages/DotNetEnv/2.3.0)
- [Hl7.Fhir.R5 Version 3.8.0](https://www.nuget.org/packages/Hl7.Fhir.R5/3.8.0)

Note that the FHIR library is currently for the R5 experimental version of FHIR because the Citation resource is not yet part of normative FHIR.

## Getting Started
The CEDAR API requires Basic Authentication in order to complete requests. To obtain
credentials this application searches for `CEDAR_USER` and `CEDAR_PASS` in `System.Environment`.
It also uses `DotNetEnv` to support `.env` files as an alternative. To quickly
provide credentials, create a `.env` file in this directory and fill in the values:
```
CEDAR_USER=
CEDAR_PASS=
```

To build and run the application simply:
```
dotnet run
```
and follow the prompts on the console.

## Available Demo Operations
1. **Get Artifact Types**: return a FHIR Parameters JSON string with all
available artifact types

2. **Text Search**: prompt the user for a string to use in a _text_ search then
return a FHIR Bundle JSON string containing the search results along with info
on how many results were returned. If no results are found, say so instead.

3. **Keyword Search**: prompt the user for a string to use in a _keyword_ search
then return a FHIR Bundle JSON string containing the search results along with
info on how many results were returned. If no results are found, say so instead.

4. **Text Search with Artifact Type Filtering**: prompt the user for a string to
use in a text search then further prompt the user for an available artifact
type string to use in filtering those results. Return a FHIR Bundle JSON string
containing the search results along with info on how many results were returned.
If no results are found, say so instead. If no artifact type string is provided,
fallback to a basic text search instead.
