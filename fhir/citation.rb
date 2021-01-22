# frozen_string_literal: true

class Citation < FHIR::Model

  include FHIR::Hashable
  include FHIR::Json
  include FHIR::Xml
  
  METADATA = {
    'id' => {'type'=>'id', 'path'=>'Citation.id', 'min'=>0, 'max'=>1},
    'meta' => {'type'=>'Meta', 'path'=>'Citation.meta', 'min'=>0, 'max'=>1},
    'implicitRules' => {'type'=>'uri', 'path'=>'Citation.implicitRules', 'min'=>0, 'max'=>1},
    'language' => {'valid_codes'=>{'urn:ietf:bcp:47'=>['ar', 'bn', 'cs', 'da', 'de', 'de-AT', 'de-CH', 'de-DE', 'el', 'en', 'en-AU', 'en-CA', 'en-GB', 'en-IN', 'en-NZ', 'en-SG', 'en-US', 'es', 'es-AR', 'es-ES', 'es-UY', 'fi', 'fr', 'fr-BE', 'fr-CH', 'fr-FR', 'fy', 'fy-NL', 'hi', 'hr', 'it', 'it-CH', 'it-IT', 'ja', 'ko', 'nl', 'nl-BE', 'nl-NL', 'no', 'no-NO', 'pa', 'pl', 'pt', 'pt-BR', 'ru', 'ru-RU', 'sr', 'sr-RS', 'sv', 'sv-SE', 'te', 'zh', 'zh-CN', 'zh-HK', 'zh-SG', 'zh-TW']}, 'type'=>'code', 'path'=>'Citation.language', 'min'=>0, 'max'=>1, 'binding'=>{'strength'=>'preferred', 'uri'=>'http://hl7.org/fhir/ValueSet/languages'}},
    'text' => {'type'=>'Narrative', 'path'=>'Citation.text', 'min'=>0, 'max'=>1},
    'contained' => {'type'=>'Resource', 'path'=>'Citation.contained', 'min'=>0, 'max'=>Float::INFINITY},
    'extension' => {'type'=>'Extension', 'path'=>'Citation.extension', 'min'=>0, 'max'=>Float::INFINITY},
    'modifierExtension' => {'type'=>'Extension', 'path'=>'Citation.modifierExtension', 'min'=>0, 'max'=>Float::INFINITY},
    'url' => {'type'=>'uri', 'path'=>'Citation.url', 'min'=>0, 'max'=>1},
    'identifier' => {'type'=>'Identifier', 'path'=>'Citation.identifier', 'min'=>0, 'max'=>Float::INFINITY},
    'title' => {'type'=>'string', 'path'=>'Citation.title', 'min'=>0, 'max'=>1},
    'status' => {'valid_codes'=>{'http://hl7.org/fhir/publication-status'=>['draft', 'active', 'retired', 'unknown']}, 'type'=>'code', 'path'=>'Citation.status', 'min'=>1, 'max'=>1, 'binding'=>{'strength'=>'required', 'uri'=>'http://hl7.org/fhir/ValueSet/publication-status'}},
    'date' => {'type'=>'date', 'path'=>'Citation.date', 'min'=>0, 'max'=>1},
    'publisher' => {'type'=>'string', 'path'=>'Citation.publisher', 'min'=>0, 'max'=>1},
    'description' => {'type'=>'markdown', 'path'=>'Citation.description', 'min'=>0, 'max'=>1},
    'webLocation' => {'type'=>'Citation::WebLocation', 'path'=>'Citation.webLocation', 'min'=>0, 'max'=>1},
    'keywordList' => {'type'=>'Citation::KeywordList', 'path'=>'Citation.keywordList', 'min'=>0, 'max'=>Float::INFINITY}
  }
  
  class WebLocation < FHIR::Model

    include FHIR::Hashable
    include FHIR::Json
    include FHIR::Xml

    METADATA = {
      'id' => {'type'=>'id', 'path'=>'WebLocation.id', 'min'=>0, 'max'=>1},
      'extension' => {'type'=>'Extension', 'path'=>'WebLocation.extension', 'min'=>0, 'max'=>Float::INFINITY},
      'modifierExtension' => {'type'=>'Extension', 'path'=>'Citation.modifierExtension', 'min'=>0, 'max'=>Float::INFINITY},
      'type' => {'valid_codes'=>{'http://terminology.hl7.org/CodeSystem/article-url-type'=>['abstract', 'abstract-cited', 'DOI-based', 'full-text', 'full-text-cited', 'PDF', 'PDF-cited', 'not-specified', 'JSON', 'XML']}, 'type'=>'CodeableConcept', 'path'=>'WebLocation.type', 'min'=>0, 'max'=>1, 'binding'=>{'strength'=>'extensible', 'uri'=>'http://hl7.org/fhir/ValueSet/article-url-type'}},
      'url' => {'type'=>'uri', 'path'=>'WebLocation.url', 'min'=>0, 'max'=>1}
    }
    
    attr_accessor :type
    attr_accessor :url
  end

  class KeywordList < FHIR::Model

    include FHIR::Hashable
    include FHIR::Json
    include FHIR::Xml

    METADATA = {
      'id' => {'type'=>'id', 'path'=>'KeywordList.id', 'min'=>0, 'max'=>1},
      'extension' => {'type'=>'Extension', 'path'=>'KeywordList.extension', 'min'=>0, 'max'=>Float::INFINITY},
      'modifierExtension' => {'type'=>'Extension', 'path'=>'KeywordList.modifierExtension', 'min'=>0, 'max'=>Float::INFINITY},
      'owner' => {'type'=>'string', 'path'=>'KeywordList.owner', 'min'=>0, 'max'=>1},
      'keyword' => {'type'=>'Citation::KeywordList::Keyword', 'path'=>'KeywordList.keyword', 'min'=>0, 'max'=>Float::INFINITY}
    }

    class Keyword < FHIR::Model

      include FHIR::Hashable
      include FHIR::Json
      include FHIR::Xml

      METADATA = {
        'id' => {'type'=>'id', 'path'=>'Keyword.id', 'min'=>0, 'max'=>1},
        'extension' => {'type'=>'Extension', 'path'=>'Keyword.extension', 'min'=>0, 'max'=>Float::INFINITY},
        'modifierExtension' => {'type'=>'Extension', 'path'=>'Keyword.modifierExtension', 'min'=>0, 'max'=>Float::INFINITY},
        'majorTopic' => {'type'=>'boolean', 'path'=>'Keyword.majorTopic', 'min'=>0, 'max'=>1},
        'value' => {'type'=>'string', 'path'=>'Keyword.value', 'min'=>1, 'max'=>1}
      }

      attr_accessor :majorTopic
      attr_accessor :value
    end

    attr_accessor :owner
    attr_accessor :keyword
  end

  attr_accessor :id                 # 0-1 id
  attr_accessor :meta               # 0-1 Meta
  attr_accessor :implicitRules      # 0-1 uri
  attr_accessor :language           # 0-1 code
  attr_accessor :text               # 0-1 Narrative
  attr_accessor :contained          # 0-* [ Resource ]
  attr_accessor :extension          # 0-* [ Extension ]
  attr_accessor :modifierExtension  # 0-* [ Extension ]
  attr_accessor :url                # 0-1 uri
  attr_accessor :identifier         # 0-* [ Identifier ]
  attr_accessor :title              # 0-1 string
  attr_accessor :status             # 1-1 code
  attr_accessor :date               # 0-1 date
  attr_accessor :publisher          # 0-1 publisher
  attr_accessor :description        # 0-1 markdown
  attr_accessor :webLocation        # 0-1 WebLocation

  def resourceType
    'Citation'
  end
end
