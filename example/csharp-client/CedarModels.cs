using System.Text.Json.Serialization;
using Newtonsoft.Json;


namespace CEDARModels
{
  // Artifact Types Result  ...................................................
  public class Parameters {
    [JsonPropertyName("resourceType")]
    public string? resourceType { get; set; }

    [JsonPropertyName("parameter")]
    public List<ParametersParameterComponent> parameter { get; set; } = new List<ParametersParameterComponent>();

    public override string ToString() {
      JsonConvert.DefaultSettings = () => new JsonSerializerSettings {
        Formatting = Formatting.Indented,
        DefaultValueHandling = DefaultValueHandling.Ignore,
      };
      string jsonString = JsonConvert.SerializeObject(this);
      return jsonString;
    }
  }

  public class ParametersParameterComponent {
    [JsonPropertyName("name")]
    public string? name { get; set; }

    [JsonPropertyName("valueCoding")]
    public Coding valueCoding { get; set; } = new Coding();
  }

  public class Coding {
    [JsonPropertyName("code")]
    public string? code { get; set; }

    [JsonPropertyName("system")]
    public string? system { get; set; }

    [JsonPropertyName("display")]
    public string? display { get; set; }
  }

  // Text Search Result .......................................................
  class Bundle {
    [JsonPropertyName("resourceType")]
    public string? resourceType { get; set; }

    [JsonPropertyName("type")]
    public string? type { get; set; }

    [JsonPropertyName("total")]
    public int? total { get; set; }

    [JsonPropertyName("link")]
    public List<BundleLinkComponent> link { get; set; } = new List<BundleLinkComponent>();

    [JsonPropertyName("entry")]
    public List<BundleEntryComponent> entry { get; set; } = new List<BundleEntryComponent>();


    public override string ToString() {
      JsonConvert.DefaultSettings = () => new JsonSerializerSettings {
        Formatting = Formatting.Indented,
        DefaultValueHandling = DefaultValueHandling.Ignore,
      };
      string jsonString = JsonConvert.SerializeObject(this);
      return jsonString;
    }
  }

  public class BundleLinkComponent {
    [JsonPropertyName("relation")]
    public string? relation { get; set; }

    [JsonPropertyName("url")]
    public string? url { get; set; }
  }

  public class BundleEntryComponent {
    [JsonPropertyName("resource")]
    public Resource resource { get; set; } = new Resource();
  }

  public class Resource {
    [JsonPropertyName("id")]
    public string? id { get; set; }

    [JsonPropertyName("meta")]
    public Meta meta { get; set; } = new Meta();

    [JsonPropertyName("text")]
    public Text text { get; set; } = new Text();

    [JsonPropertyName("url")]
    public string? url { get; set; }

    [JsonPropertyName("identifier")]
    public List<Identifier> identifier { get; set; } = new List<Identifier>();

    [JsonPropertyName("title")]
    public string? title { get; set; }

    [JsonPropertyName("status")]
    public string? status { get; set; }

    [JsonPropertyName("date")]
    public string? date { get; set; }

    [JsonPropertyName("publisher")]
    public string? publisher { get; set; }

    [JsonPropertyName("contact")]
    public List<ContactDetail> contact { get; set; } = new List<ContactDetail>();

    [JsonPropertyName("citedArtifact")]
    public CitationCitedArtifactComponent citedArtifact { get; set; } = new CitationCitedArtifactComponent();

    [JsonPropertyName("resourceType")]
    public string? resourceType { get; set; }
  }

  public class Meta {
    [JsonPropertyName("versionId")]
    public int? id { get; set; }
  }

  public class Text {
    [JsonPropertyName("status")]
    public string? status { get; set; }

    [JsonPropertyName("div")]
    public string? div { get; set; }
  }

  public class Identifier {
    [JsonPropertyName("system")]
    public string? system { get; set; }

    [JsonPropertyName("value")]
    public string? value { get; set; }
  }

  public class ContactDetail {
    [JsonPropertyName("name")]
    public string? name { get; set; }

    [JsonPropertyName("telecom")]
    public List<ContactPoint> telecom { get; set; } = new List<ContactPoint>();
  }

  public class ContactPoint {
    [JsonPropertyName("system")]
    public string? system { get; set; }

    [JsonPropertyName("value")]
    public string? value { get; set; }

    [JsonPropertyName("use")]
    public string? use { get; set; }
  }

  public class CitationCitedArtifactComponent {
    [JsonPropertyName("identifier")]
    public List<Identifier> identifier { get; set; } = new List<Identifier>();

    [JsonPropertyName("dateAccessed")]
    public string? dateAccessed { get; set; }

    [JsonPropertyName("currentState")]
    public List<CodeableConcept> currentState { get; set; } = new List<CodeableConcept>();

    [JsonPropertyName("title")]
    public List<CitationTitleComponent> title { get; set; } = new List<CitationTitleComponent>();

    // can't use abstract; reserved keyword
    [JsonPropertyName("abstract")]
    public List<CitationAbstractComponent> abstractComponent { get; set; } = new List<CitationAbstractComponent>();

    [JsonPropertyName("publicationForm")]
    public List<CitationPublicationFormComponent> publicationForm { get; set; } = new List<CitationPublicationFormComponent>();

    [JsonPropertyName("webLocation")]
    public List<CitationWebLocationComponent> webLocation { get; set; } = new List<CitationWebLocationComponent>();
  }

  public class CodeableConcept {
    [JsonPropertyName("id")]
    public string? id { get; set; }

    [JsonPropertyName("text")]
    public string? text { get; set; }

    [JsonPropertyName("coding")]
    public List<Coding> coding { get; set; } = new List<Coding>();
  }

  public class CitationTitleComponent {
    [JsonPropertyName("text")]
    public string? text { get; set; }

    [JsonPropertyName("type")]
    public CodeableConcept type { get; set; } = new CodeableConcept();

    [JsonPropertyName("language")]
    public CodeableConcept language { get; set; } = new CodeableConcept();
  }

  public class CitationAbstractComponent {
    [JsonPropertyName("text")]
    public string? text { get; set; }

    [JsonPropertyName("type")]
    public CodeableConcept type { get; set; } = new CodeableConcept();

    [JsonPropertyName("language")]
    public CodeableConcept language { get; set; } = new CodeableConcept();
  }

  public class CitationPublicationFormComponent {
    [JsonPropertyName("publishedIn")]
    public CitationPublishedInComponent publishedIn { get; set; } = new CitationPublishedInComponent();

    [JsonPropertyName("articleDate")]
    public string? articleDate { get; set; }

    [JsonPropertyName("language")]
    public List<CodeableConcept> language { get; set; } = new List<CodeableConcept>();
  }

  public class CitationPublishedInComponent {
    [JsonPropertyName("type")]
    public CodeableConcept type { get; set; } = new CodeableConcept();

    [JsonPropertyName("title")]
    public string? title { get; set; }

    [JsonPropertyName("publisher")]
    public Reference publisher { get; set; } = new Reference();
  }

  public class Reference {
    [JsonPropertyName("reference")]
    public string? reference { get; set; }

    [JsonPropertyName("display")]
    public string? display { get; set; }
  }

  public class CitationWebLocationComponent {
    [JsonPropertyName("type")]
    public CodeableConcept type { get; set; } = new CodeableConcept();

    [JsonPropertyName("url")]
    public string? url { get; set; }
  }

  public class CitationClassificationComponent {
    [JsonPropertyName("type")]
    public CodeableConcept type { get; set; } = new CodeableConcept();

    [JsonPropertyName("classifier")]
    public List<CodeableConcept> classifier { get; set; } = new List<CodeableConcept>();

    [JsonPropertyName("whoClassified")]
    public CitationWhoClassifiedComponent whoClassified { get; set; } = new CitationWhoClassifiedComponent();
  }

  public class CitationWhoClassifiedComponent {
    [JsonPropertyName("publisher")]
    public Reference publisher { get; set; } = new Reference();
  }
}
