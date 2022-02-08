using System.Text;
using System.Net.Http.Headers;
using Bundle = Hl7.Fhir.Model.Bundle;
using Parameters = Hl7.Fhir.Model.Parameters;
using Hl7.Fhir.Serialization;

/**
 * CEDARClient namespace contains two classes implementing a basic dotnet 
 * console app to demo usage of basic CEDAR API functionality. Also takes
 * advantage of the C# FHIR SDK's implementation of the FHIR standard to provide
 * interoperability, serialization, and deserialization without additional effort.
 */
namespace CEDARClient
{
  /**
   * APIClient makes HttpClient requests to a running instance of the CEDAR
   * API (assumed to be http://localhost:4567 by default) while FhirJsonParser
   * from the FHIR SDK parses incoming FHIR+JSON responses from the CEDAR API
   * into locally usable objects. It demos CEDAR functionality for searches and
   * resource retrieval. For additional CEDAR API functionality, see CEDAR API docs
   */
  class APIClient {
    private static readonly HttpClient client = new HttpClient();
    private static readonly string apiHost = "http://localhost:4567";

    /**
     * CEDAR API responses seem to contain some members that don't exactly match
     * up to SDK definitions (maybe because SDK version is currently listed as 
     * experimental). Accept them to avoid error, but they won't be available on
     * the parsed object.
     */ 
    private static FhirJsonParser fhirParser = new FhirJsonParser(
      new ParserSettings { AcceptUnknownMembers = true }
    );

    /**
     * Demo CEDAR API resource retrieval via Artifact Types
     * - API Request: GET /fhir/Citation/$get-artifact-types
     * - Response: Parameter FHIR model in application/fhir+json format
     */
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
        Console.WriteLine("ERROR: Unable to complete client request.\n{0}", error.StackTrace);
        throw;
      }
    }

    /**
     * Demo CEDAR API search functionality with some basic query params/filters
     * (more available, see CEDAR API docs)
     * - API Request: GET /fhir/Citation?<query params>
     * - Response: Bundle FHIR model in application/fhir+json format
     * + Supported Params:
     *   - count: number of items per page to be included in your bundle. default = 10
     *   - page: desired page to be viewed in your bundle. default = 1
     *   - artifactState: enum; either active, retired, draft, or unknown. default = active
     *   - searchString: populated for searches of citations by text, otherwise null
     *   - keywordString: populated for searches of citations by keyword, otherwise null
     *   - artifactTypeString: filter for searches of citations by an available
     *                         artifact type as indicated by GetArtifactTypes(), otherwise null
     */
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
        Console.WriteLine("ERROR: Unable to complete client request.\n{0}", error.StackTrace);
        throw;
      }
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
  }

  /**
   * ConsoleApp is a toy example allowing for APIClient to be called via
   * `dotnet run` (which also handles building the project). It presents four
   * options corresponding to APIClient methods and uses
   * ControlFlow(methodSelection) to handle the bulk of console app I/O.
   */
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

    /**
     * Uses selection from Main() to run a demo method. Depending on method,
     * further console input is piped to method as parameters. Output for each
     * method simply utilizes FhirSerializer from the FHIR SDK to print the
     * parsed FHIR model (received as a response from CEDAR API) back to the
     * console as a prettified JSON string. Also demos use of parsed model to 
     * report number of results returned from search methods.
     */
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
          Console.WriteLine("Successfully returned {0} result(s).", textSearchBundle.Total);
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
          Console.WriteLine("Successfully returned {0} result(s).", keywordSearchBundle.Total);
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
            Console.WriteLine("Successfully returned {0} fallback result(s).", fallbackBundle.Total);
            break;
          }
          Bundle filteredTextSearchBundle = await APIClient.FilteredTextSearch(filteredTextQuery, artifactTypeFilter);
          if (filteredTextSearchBundle.Total == 0) {
            Console.WriteLine("No search results");
            break;
          }
          string filteredTextSearchContent = fhirSerializer.SerializeToString(filteredTextSearchBundle);
          Console.WriteLine(filteredTextSearchContent);
          Console.WriteLine("Successfully returned {0} result(s).", filteredTextSearchBundle.Total);
          break;

        default:
          throw new Exception("Unknown demo method. Exiting.");
      }
    }
  }
}
