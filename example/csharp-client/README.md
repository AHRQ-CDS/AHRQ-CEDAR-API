# Example C# Client App
This is a small C# console app implementing some basic CEDAR API client demo
functionality. Since the CEDAR API implements the FHIR standard, the client
takes advantage of the [firely-net-sdk FHIR SDK](https://github.com/FirelyTeam/firely-net-sdk/tree/develop-r5)
for deserialization (parsing) and serialization.

## Prerequisites
- [dotnet](https://docs.microsoft.com/en-us/dotnet/core/install/)

## Build & Run
You may consider editing the `apiHost` variable in `CEDARClient.cs` depending on
where the CEDAR API instance you plan to use is hosted. By default it is:
```C#
private static readonly string apiHost = "http://localhost:4567";
```
Once ready, simply:
```
dotnet run
```
and follow the prompts from the console app.

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
