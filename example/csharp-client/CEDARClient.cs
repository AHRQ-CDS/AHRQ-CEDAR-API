using System.IO;
using System.Text;
using System.Net.Http.Headers;
using Bundle = Hl7.Fhir.Model.Bundle;
using Parameters = Hl7.Fhir.Model.Parameters;
using Hl7.Fhir.Serialization;


namespace CEDARClient
{
  class APIClient {
    private static readonly HttpClient client = new HttpClient();
    private static readonly string apiHost = "http://localhost:4567";
    // Since CEDAR implements FHIR, we can just use the FHIR SDK
    private static FhirJsonParser fhirParser = new FhirJsonParser(
      new ParserSettings { AcceptUnknownMembers = true }
    );

    // Retrieval of all artifact types
    public static async Task<Parameters> GetArtifactTypes() {
      client.DefaultRequestHeaders.Accept.Clear();
      client.DefaultRequestHeaders.Accept.Add(
        new MediaTypeWithQualityHeaderValue("application/fhir+json"));

      try {
        var request = client.GetStreamAsync(apiHost + "/fhir/Citation/$get-artifact-types");
        using (var reader = new StreamReader(await request, Encoding.UTF8)) {
          Parameters fhirParameters = fhirParser.Parse<Parameters>(reader.ReadToEnd());
          return fhirParameters;
        }
      } catch (Exception error) {
        Console.WriteLine(error.ToString());
      }
      throw new Exception("Unknown Error");
    }

    private static async Task<Bundle> Search(
      string? searchString, string? keywordString, string? artifactTypeString,
      int count = 10, int page = 1, string artifactState = "active")
    {
      client.DefaultRequestHeaders.Accept.Clear();
      client.DefaultRequestHeaders.Accept.Add(
        new MediaTypeWithQualityHeaderValue("application/fhir+json"));

      UriBuilder queryBuilder = new UriBuilder(apiHost + "/fhir/Citation");
      queryBuilder.Query = String.Format(
        "_count={0}&page={1}&artifact-current-state={2}", count, page, artifactState);

      if (searchString != null) {
        queryBuilder.Query += String.Format("&_content={0}", searchString);
      }
      if (keywordString != null) {
        queryBuilder.Query += String.Format("&classification:text={0}", keywordString);
      }
      if (artifactTypeString != null) {
        queryBuilder.Query += String.Format("&artifact-type={0}", artifactTypeString);
      }

      try {
        var request = client.GetStreamAsync(queryBuilder.Uri);
        using (var reader = new StreamReader(await request, Encoding.UTF8)) {
          Bundle fhirBundle = fhirParser.Parse<Bundle>(reader.ReadToEnd());
          return fhirBundle;
        }
      } catch (Exception error) {
        Console.WriteLine(error.ToString());
      }
      throw new Exception("Unknown Error");
    }

    // Basic text search
    public static async Task<Bundle> TextSearch(string searchString) {
      return await Search(searchString, null, null);
    }

    // Keyword search
    public static async Task<Bundle> KeywordSearch(string keywordString) {
      return await Search(null, keywordString, null);
    }

    // Text search with added artifact type filtering
    public static async Task<Bundle> FilteredTextSearch(string searchString, string artifactTypeFilter) {
      return await Search(searchString, null, artifactTypeFilter);
    }

    // Parsing responses and pulling out key data elements
    // Deserialization (Parsing) and Serialization provided by Hl7.Fhir.R5 package
    // Example use of parsed property Bundle.Total below
  }

  class ConsoleApp {
    private static FhirJsonSerializer fhirSerializer = new FhirJsonSerializer(
      new SerializerSettings() { Pretty = true }
    );

    static async Task Main(string[] args) {
      Console.WriteLine("CEDAR API C# Client Demo:");
      Console.WriteLine("  1. Get Artifact Types");
      Console.WriteLine("  2. Text Search");
      Console.WriteLine("  3. Keyword Search");
      Console.WriteLine("  4. Text Search with Artifact Type Filtering");
      Console.WriteLine("Select an operation [1-4]:");
      var input = Console.ReadLine();
      input = input != null ? input : "";

      try {
        int methodSelection = Int32.Parse(input);
        await ControlFlow(methodSelection);
      } catch (Exception error) {
        Console.WriteLine(error.ToString());
      }

      Console.WriteLine("\nDemo Operation Complete. Exiting.");
      Environment.Exit(0);
    }

    private static async Task ControlFlow(int methodSelection) {
      switch (methodSelection) {
        // Get Artifact Types
        case 1:
          Parameters fhirParameters = await APIClient.GetArtifactTypes();
          string parametersContent = fhirSerializer.SerializeToString(fhirParameters);
          Console.WriteLine(parametersContent);
          break;

        // Text Search
        case 2:
          Console.WriteLine("Enter search term(s):");
          string? textQuery = Console.ReadLine();
          if (textQuery == null) {
            Console.WriteLine("No search results");
            break;
          }
          Bundle textSearchBundle = await APIClient.TextSearch(textQuery);
          if (textSearchBundle.Total == 0) {
            Console.WriteLine("No search results");
            break;
          }
          string textSearchContent = fhirSerializer.SerializeToString(textSearchBundle);
          Console.WriteLine(textSearchContent);
          Console.WriteLine(String.Format("Successfully returned {0} result(s).", textSearchBundle.Total));
          break;

        // Keyword Search
        case 3:
          Console.WriteLine("Enter keyword(s):");
          string? keywordQuery = Console.ReadLine();
          if (keywordQuery == null) {
            Console.WriteLine("No search results");
            break;
          }
          Bundle keywordSearchBundle = await APIClient.KeywordSearch(keywordQuery);
          if (keywordSearchBundle.Total == 0) {
            Console.WriteLine("No search results");
            break;
          }
          string keywordSearchContent = fhirSerializer.SerializeToString(keywordSearchBundle);
          Console.WriteLine(keywordSearchContent);
          Console.WriteLine(String.Format("Successfully returned {0} result(s).", keywordSearchBundle.Total));
          break;

        // Text Search with Artifact Type Filtering
        case 4:
          Console.WriteLine("Enter search term(s):");
          string? filteredTextQuery = Console.ReadLine();
          if (filteredTextQuery == null) {
            Console.WriteLine("No search results");
            break;
          }
          Console.WriteLine("Enter artifact type to filter by:");
          string? artifactTypeFilter = Console.ReadLine();
          if (artifactTypeFilter == null || artifactTypeFilter == "") {
            Console.WriteLine("No filter provided. Falling back to basic text search results.");
            Bundle fallbackBundle = await APIClient.TextSearch(filteredTextQuery);
            if (fallbackBundle.Total == 0) {
              Console.WriteLine("No search results");
              break;
            }
            string fallbackContent = fhirSerializer.SerializeToString(fallbackBundle);
            Console.WriteLine(fallbackContent);
            Console.WriteLine(String.Format("Successfully returned {0} fallback result(s).", fallbackBundle.Total));
            break;
          }
          Bundle filteredTextSearchBundle = await APIClient.FilteredTextSearch(filteredTextQuery, artifactTypeFilter);
          if (filteredTextSearchBundle.Total == 0) {
            Console.WriteLine("No search results");
            break;
          }
          string filteredTextSearchContent = fhirSerializer.SerializeToString(filteredTextSearchBundle);
          Console.WriteLine(filteredTextSearchContent);
          Console.WriteLine(String.Format("Successfully returned {0} result(s).", filteredTextSearchBundle.Total));
          break;

        default:
          throw new Exception("Unknown demo method. Exiting.");
      }
    }
  }
}
