using System.Net.Http.Headers;
using System.Text.Json;
using CEDARModels;


namespace CEDARClient
{
  class APIClient {
    private static readonly HttpClient client = new HttpClient();
    private static readonly string apiHost = "http://localhost:4567";

    public static async Task<Bundle> Search(
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
        var response = await JsonSerializer.DeserializeAsync<Bundle>(await request);
        if (response != null) {
          return response;
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

    // Retrieval of all artifact types
    public static async Task<Parameters> GetArtifactTypes()
    {
      client.DefaultRequestHeaders.Accept.Clear();
      client.DefaultRequestHeaders.Accept.Add(
        new MediaTypeWithQualityHeaderValue("application/fhir+json"));

      try {
        var request = client.GetStreamAsync(apiHost + "/fhir/Citation/$get-artifact-types");
        var response = await JsonSerializer.DeserializeAsync<Parameters>(await request);
        if (response != null) {
          return response;
        }
      } catch (Exception error) {
        Console.WriteLine(error.ToString());
      }
      throw new Exception("Unknown Error");
    }

    // Text search with added artifact type filtering
    public static async Task<Bundle> FilteredTextSearch(string searchString, string artifactTypeFilter) {
      return await Search(searchString, null, artifactTypeFilter);
    }

    // Parsing responses and pulling out key data elements
    // > Please refer to CedarModels for a partial implementation of available CEDAR API data models
  }

  class ConsoleApp {
    static async Task Main(string[] args) {
      Console.WriteLine("CEDAR API C# Client Demo:");
      Console.WriteLine("-------------------------");
      Console.WriteLine("Select a method ['GetArtifactTypes', 'TextSearch', 'KeywordSearch', 'FilteredTextSearch']:");
      string? methodSelection = Console.ReadLine();
      methodSelection = methodSelection?.ToLower(); // Attempt to mitigate some user error

      try {
        await ControlFlow(methodSelection);
      } catch (Exception error) {
        Console.WriteLine(error.ToString());
      }
      
      Console.WriteLine("Demo Complete. Exiting.");
      Environment.Exit(0);
    }

    static async Task ControlFlow(string? methodSelection) {
      switch (methodSelection)
      {
        case "getartifacttypes":
          var artifactTypes = await APIClient.GetArtifactTypes();
          Console.WriteLine(artifactTypes.ToString());
          break;

        case "textsearch":
          Console.WriteLine("Enter search term(s):");
          string? textQuery = Console.ReadLine();
          if (textQuery == null)
          {
            Console.WriteLine("No search results");
            break;
          }
          var textSearchResults = await APIClient.TextSearch(textQuery);
          if (textSearchResults.total == 0)
          {
            Console.WriteLine("No search results");
            break;
          }
          Console.WriteLine(textSearchResults.ToString());
          Console.WriteLine(String.Format("Successfully returned {0} result(s).", textSearchResults.total));
          break;

        case "keywordsearch":
          Console.WriteLine("Enter keyword(s) :");
          string? keywordQuery = Console.ReadLine();
          if (keywordQuery == null) {
            Console.WriteLine("No search results");
            break;
          }
          var keywordSearchResults = await APIClient.KeywordSearch(keywordQuery);
          if (keywordSearchResults.total == 0) {
            Console.WriteLine("No search results");
            break;
          }
          Console.WriteLine(keywordSearchResults.ToString());
          Console.WriteLine(String.Format("Successfully returned {0} result(s).", keywordSearchResults.total));
          break;

        case "filteredtextsearch":
          Console.WriteLine("Enter search terms:");
          string? filteredTextQuery = Console.ReadLine();
          if (filteredTextQuery == null) {
            Console.WriteLine("No search results");
            break;
          }
          Console.WriteLine("Enter artifact type to filter by:");
          string? artifactTypeFilter = Console.ReadLine();
          if (artifactTypeFilter == null || artifactTypeFilter == "") {
            Console.WriteLine("No filter provided. Falling back to basic text search results");
            var fallback = await APIClient.TextSearch(filteredTextQuery);
            if (fallback.total == 0) {
              Console.WriteLine("No search results");
              break;
            }
            Console.WriteLine(fallback.ToString());
            Console.WriteLine(String.Format("Successfully returned {0} fallback result(s).", fallback.total));
            break;
          }
          var filteredTextSearchResults = await APIClient.FilteredTextSearch(filteredTextQuery, artifactTypeFilter);
          if (filteredTextSearchResults.total == 0) {
            Console.WriteLine("No search results");
            break;
          }
          Console.WriteLine(filteredTextSearchResults.ToString());
          Console.WriteLine(String.Format("Successfully returned {0} result(s).", filteredTextSearchResults.total));
          break;

        default:
          throw new Exception("Unknown demo method. Exiting.");
      }
    }
  }
}
