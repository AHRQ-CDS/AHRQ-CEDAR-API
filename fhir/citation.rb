module FHIR
  class Citation < FHIR::Model
    include FHIR::Hashable
    include FHIR::Json
    include FHIR::Xml

    SEARCH_PARAMS = []
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
      'relatedIdentifier' => {'type'=>'Identifier', 'path'=>'Citation.relatedIdentifier', 'min'=>0, 'max'=>Float::INFINITY},
      'version' => {'type'=>'string', 'path'=>'Citation.version', 'min'=>0, 'max'=>1},
      'name' => {'type'=>'string', 'path'=>'Citation.name', 'min'=>0, 'max'=>1},
      'title' => {'type'=>'string', 'path'=>'Citation.title', 'min'=>0, 'max'=>1},
      'status' => {'valid_codes'=>{'http://hl7.org/fhir/publication-status'=>['draft', 'active', 'retired', 'unknown']}, 'type'=>'code', 'path'=>'Citation.status', 'min'=>1, 'max'=>1, 'binding'=>{'strength'=>'required', 'uri'=>'http://hl7.org/fhir/ValueSet/publication-status'}},
      'experimental' => {'type'=>'boolean', 'path'=>'Citation.experimental', 'min'=>0, 'max'=>1},
      'date' => {'type'=>'dateTime', 'path'=>'Citation.date', 'min'=>0, 'max'=>1},
      'publisher' => {'type'=>'string', 'path'=>'Citation.publisher', 'min'=>0, 'max'=>1},
      'contact' => {'type'=>'ContactDetail', 'path'=>'Citation.contact', 'min'=>0, 'max'=>Float::INFINITY},
      'description' => {'type'=>'markdown', 'path'=>'Citation.description', 'min'=>0, 'max'=>1},
      'useContext' => {'type'=>'UsageContext', 'path'=>'Citation.useContext', 'min'=>0, 'max'=>Float::INFINITY},
      'jurisdiction' => {'type'=>'CodeableConcept', 'path'=>'Citation.jurisdiction', 'min'=>0, 'max'=>Float::INFINITY, 'binding'=>{'strength'=>'extensible', 'uri'=>'http://hl7.org/fhir/ValueSet/jurisdiction'}},
      'purpose' => {'type'=>'markdown', 'path'=>'Citation.purpose', 'min'=>0, 'max'=>1},
      'approvalDate' => {'type'=>'date', 'path'=>'Citation.approvalDate', 'min'=>0, 'max'=>1},
      'lastReviewDate' => {'type'=>'date', 'path'=>'Citation.lastReviewDate', 'min'=>0, 'max'=>1},
      'effectivePeriod' => {'type'=>'Period', 'path'=>'Citation.effectivePeriod', 'min'=>0, 'max'=>1},
      'summary' => {'type'=>'Citation::Summary', 'path'=>'Citation.summary', 'min'=>0, 'max'=>Float::INFINITY},
      'dateCited' => {'type'=>'dateTime', 'path'=>'Citation.dateCited', 'min'=>0, 'max'=>1},
      'variantCitation' => {'type'=>'Citation::VariantCitation', 'path'=>'Citation.variantCitation', 'min'=>0, 'max'=>1},
      'articleTitle' => {'type'=>'Citation::ArticleTitle', 'path'=>'Citation.articleTitle', 'min'=>0, 'max'=>Float::INFINITY},
      'webLocation' => {'type'=>'Citation::WebLocation', 'path'=>'Citation.webLocation', 'min'=>0, 'max'=>Float::INFINITY},
      'abstract' => {'type'=>'Citation::Abstract', 'path'=>'Citation.abstract', 'min'=>0, 'max'=>Float::INFINITY},
      'contributorship' => {'type'=>'Citation::Contributorship', 'path'=>'Citation.contributorship', 'min'=>0, 'max'=>1},
      'publicationForm' => {'type'=>'Citation::PublicationForm', 'path'=>'Citation.publicationForm', 'min'=>0, 'max'=>Float::INFINITY},
      'classifier' => {'type'=>'CodeableConcept', 'path'=>'Citation.classifier', 'min'=>0, 'max'=>Float::INFINITY, 'binding'=>{'strength'=>'extensible', 'uri'=>'http://hl7.org/fhir/ValueSet/citation-classifier'}},
      'keywordList' => {'type'=>'Citation::KeywordList', 'path'=>'Citation.keywordList', 'min'=>0, 'max'=>Float::INFINITY},
      'relatedArtifact' => {'type'=>'RelatedArtifact', 'path'=>'Citation.relatedArtifact', 'min'=>0, 'max'=>Float::INFINITY},
      'note' => {'type'=>'Annotation', 'path'=>'Citation.note', 'min'=>0, 'max'=>Float::INFINITY},
      'medline' => {'type'=>'Citation::Medline', 'path'=>'Citation.medline', 'min'=>0, 'max'=>1}
    }

    class Summary < FHIR::Model
      include FHIR::Hashable
      include FHIR::Json
      include FHIR::Xml

      METADATA = {
        'id' => {'type'=>'string', 'path'=>'Summary.id', 'min'=>0, 'max'=>1},
        'extension' => {'type'=>'Extension', 'path'=>'Summary.extension', 'min'=>0, 'max'=>Float::INFINITY},
        'modifierExtension' => {'type'=>'Extension', 'path'=>'Summary.modifierExtension', 'min'=>0, 'max'=>Float::INFINITY},
        'style' => {'type'=>'CodeableConcept', 'path'=>'Summary.style', 'min'=>0, 'max'=>1, 'binding'=>{'strength'=>'extensible', 'uri'=>'http://hl7.org/fhir/ValueSet/citation-summary-style'}},
        'text' => {'type'=>'markdown', 'path'=>'Summary.text', 'min'=>1, 'max'=>1}
      }

      attr_accessor :id                # 0-1 string
      attr_accessor :extension         # 0-* [ Extension ]
      attr_accessor :modifierExtension # 0-* [ Extension ]
      attr_accessor :style             # 0-1 CodeableConcept
      attr_accessor :text              # 1-1 markdown
    end

    class VariantCitation < FHIR::Model
      include FHIR::Hashable
      include FHIR::Json
      include FHIR::Xml

      METADATA = {
        'id' => {'type'=>'string', 'path'=>'VariantCitation.id', 'min'=>0, 'max'=>1},
        'extension' => {'type'=>'Extension', 'path'=>'VariantCitation.extension', 'min'=>0, 'max'=>Float::INFINITY},
        'modifierExtension' => {'type'=>'Extension', 'path'=>'VariantCitation.modifierExtension', 'min'=>0, 'max'=>Float::INFINITY},
        'type' => {'type'=>'CodeableConcept', 'path'=>'VariantCitation.type', 'min'=>0, 'max'=>1, 'binding'=>{'strength'=>'extensible', 'uri'=>'http://hl7.org/fhir/ValueSet/citation-variant-type'}},
        'value' => {'type'=>'string', 'path'=>'VariantCitation.value', 'min'=>0, 'max'=>1},
        'baseCitation' => {'type_profiles'=>['http://hl7.org/fhir/StructureDefinition/Citation'], 'type'=>'Reference', 'path'=>'VariantCitation.baseCitation', 'min'=>0, 'max'=>1}
      }

      attr_accessor :id                # 0-1 string
      attr_accessor :extension         # 0-* [ Extension ]
      attr_accessor :modifierExtension # 0-* [ Extension ]
      attr_accessor :type              # 0-1 CodeableConcept
      attr_accessor :value             # 0-1 string
      attr_accessor :baseCitation      # 0-1 Reference(Citation)
    end

    class ArticleTitle < FHIR::Model
      include FHIR::Hashable
      include FHIR::Json
      include FHIR::Xml

      METADATA = {
        'id' => {'type'=>'string', 'path'=>'ArticleTitle.id', 'min'=>0, 'max'=>1},
        'extension' => {'type'=>'Extension', 'path'=>'ArticleTitle.extension', 'min'=>0, 'max'=>Float::INFINITY},
        'modifierExtension' => {'type'=>'Extension', 'path'=>'ArticleTitle.modifierExtension', 'min'=>0, 'max'=>Float::INFINITY},
        'type' => {'type'=>'CodeableConcept', 'path'=>'ArticleTitle.type', 'min'=>0, 'max'=>1, 'binding'=>{'strength'=>'extensible', 'uri'=>'http://hl7.org/fhir/ValueSet/alternative-title-type'}},
        'language' => {'valid_codes'=>{'urn:ietf:bcp:47'=>['ar', 'bn', 'cs', 'da', 'de', 'de-AT', 'de-CH', 'de-DE', 'el', 'en', 'en-AU', 'en-CA', 'en-GB', 'en-IN', 'en-NZ', 'en-SG', 'en-US', 'es', 'es-AR', 'es-ES', 'es-UY', 'fi', 'fr', 'fr-BE', 'fr-CH', 'fr-FR', 'fy', 'fy-NL', 'hi', 'hr', 'it', 'it-CH', 'it-IT', 'ja', 'ko', 'nl', 'nl-BE', 'nl-NL', 'no', 'no-NO', 'pa', 'pl', 'pt', 'pt-BR', 'ru', 'ru-RU', 'sr', 'sr-RS', 'sv', 'sv-SE', 'te', 'zh', 'zh-CN', 'zh-HK', 'zh-SG', 'zh-TW']}, 'type'=>'CodeableConcept', 'path'=>'ArticleTitle.language', 'min'=>0, 'max'=>1, 'binding'=>{'strength'=>'preferred', 'uri'=>'http://hl7.org/fhir/ValueSet/languages'}},
        'text' => {'type'=>'markdown', 'path'=>'ArticleTitle.text', 'min'=>1, 'max'=>1}
      }

      attr_accessor :id                # 0-1 string
      attr_accessor :extension         # 0-* [ Extension ]
      attr_accessor :modifierExtension # 0-* [ Extension ]
      attr_accessor :type              # 0-1 CodeableConcept
      attr_accessor :language          # 0-1 CodeableConcept
      attr_accessor :text              # 1-1 markdown
    end

    class WebLocation < FHIR::Model
      include FHIR::Hashable
      include FHIR::Json
      include FHIR::Xml

      METADATA = {
        'id' => {'type'=>'string', 'path'=>'WebLocation.id', 'min'=>0, 'max'=>1},
        'extension' => {'type'=>'Extension', 'path'=>'WebLocation.extension', 'min'=>0, 'max'=>Float::INFINITY},
        'modifierExtension' => {'type'=>'Extension', 'path'=>'WebLocation.modifierExtension', 'min'=>0, 'max'=>Float::INFINITY},
        'type' => {'type'=>'CodeableConcept', 'path'=>'WebLocation.type', 'min'=>0, 'max'=>1, 'binding'=>{'strength'=>'extensible', 'uri'=>'http://hl7.org/fhir/ValueSet/article-url-type'}},
        'url' => {'type'=>'uri', 'path'=>'WebLocation.url', 'min'=>0, 'max'=>1}
      }

      attr_accessor :id                # 0-1 string
      attr_accessor :extension         # 0-* [ Extension ]
      attr_accessor :modifierExtension # 0-* [ Extension ]
      attr_accessor :type              # 0-1 CodeableConcept
      attr_accessor :url               # 0-1 uri
    end

    class Abstract < FHIR::Model
      include FHIR::Hashable
      include FHIR::Json
      include FHIR::Xml

      METADATA = {
        'id' => {'type'=>'string', 'path'=>'Abstract.id', 'min'=>0, 'max'=>1},
        'extension' => {'type'=>'Extension', 'path'=>'Abstract.extension', 'min'=>0, 'max'=>Float::INFINITY},
        'modifierExtension' => {'type'=>'Extension', 'path'=>'Abstract.modifierExtension', 'min'=>0, 'max'=>Float::INFINITY},
        'type' => {'type'=>'CodeableConcept', 'path'=>'Abstract.type', 'min'=>0, 'max'=>1, 'binding'=>{'strength'=>'extensible', 'uri'=>'http://hl7.org/fhir/ValueSet/alternative-title-type'}},
        'language' => {'valid_codes'=>{'urn:ietf:bcp:47'=>['ar', 'bn', 'cs', 'da', 'de', 'de-AT', 'de-CH', 'de-DE', 'el', 'en', 'en-AU', 'en-CA', 'en-GB', 'en-IN', 'en-NZ', 'en-SG', 'en-US', 'es', 'es-AR', 'es-ES', 'es-UY', 'fi', 'fr', 'fr-BE', 'fr-CH', 'fr-FR', 'fy', 'fy-NL', 'hi', 'hr', 'it', 'it-CH', 'it-IT', 'ja', 'ko', 'nl', 'nl-BE', 'nl-NL', 'no', 'no-NO', 'pa', 'pl', 'pt', 'pt-BR', 'ru', 'ru-RU', 'sr', 'sr-RS', 'sv', 'sv-SE', 'te', 'zh', 'zh-CN', 'zh-HK', 'zh-SG', 'zh-TW']}, 'type'=>'CodeableConcept', 'path'=>'Abstract.language', 'min'=>0, 'max'=>1, 'binding'=>{'strength'=>'preferred', 'uri'=>'http://hl7.org/fhir/ValueSet/languages'}},
        'text' => {'type'=>'markdown', 'path'=>'Abstract.text', 'min'=>1, 'max'=>1},
        'copyright' => {'type'=>'markdown', 'path'=>'Abstract.copyright', 'min'=>0, 'max'=>1}
      }

      attr_accessor :id                # 0-1 string
      attr_accessor :extension         # 0-* [ Extension ]
      attr_accessor :modifierExtension # 0-* [ Extension ]
      attr_accessor :type              # 0-1 CodeableConcept
      attr_accessor :language          # 0-1 CodeableConcept
      attr_accessor :text              # 1-1 markdown
      attr_accessor :copyright         # 0-1 markdown
    end

    class Contributorship < FHIR::Model
      include FHIR::Hashable
      include FHIR::Json
      include FHIR::Xml

      METADATA = {
        'id' => {'type'=>'string', 'path'=>'Contributorship.id', 'min'=>0, 'max'=>1},
        'extension' => {'type'=>'Extension', 'path'=>'Contributorship.extension', 'min'=>0, 'max'=>Float::INFINITY},
        'modifierExtension' => {'type'=>'Extension', 'path'=>'Contributorship.modifierExtension', 'min'=>0, 'max'=>Float::INFINITY},
        'complete' => {'type'=>'boolean', 'path'=>'Contributorship.complete', 'min'=>0, 'max'=>1},
        'entry' => {'type'=>'Citation::Contributorship::Entry', 'path'=>'Contributorship.entry', 'min'=>0, 'max'=>Float::INFINITY},
        'summary' => {'type'=>'Citation::Contributorship::Summary', 'path'=>'Contributorship.summary', 'min'=>0, 'max'=>Float::INFINITY}
      }

      class Entry < FHIR::Model
        include FHIR::Hashable
        include FHIR::Json
        include FHIR::Xml

        METADATA = {
          'id' => {'type'=>'string', 'path'=>'Entry.id', 'min'=>0, 'max'=>1},
          'extension' => {'type'=>'Extension', 'path'=>'Entry.extension', 'min'=>0, 'max'=>Float::INFINITY},
          'modifierExtension' => {'type'=>'Extension', 'path'=>'Entry.modifierExtension', 'min'=>0, 'max'=>Float::INFINITY},
          'name' => {'type'=>'HumanName', 'path'=>'Entry.name', 'min'=>0, 'max'=>1},
          'initials' => {'type'=>'string', 'path'=>'Entry.initials', 'min'=>0, 'max'=>1},
          'collectiveName' => {'type'=>'string', 'path'=>'Entry.collectiveName', 'min'=>0, 'max'=>1},
          'identifier' => {'type'=>'Identifier', 'path'=>'Entry.identifier', 'min'=>0, 'max'=>Float::INFINITY},
          'affiliationInfo' => {'type'=>'Citation::Contributorship::Entry::AffiliationInfo', 'path'=>'Entry.affiliationInfo', 'min'=>0, 'max'=>Float::INFINITY},
          'address' => {'type'=>'Address', 'path'=>'Entry.address', 'min'=>0, 'max'=>Float::INFINITY},
          'telecom' => {'type'=>'ContactPoint', 'path'=>'Entry.telecom', 'min'=>0, 'max'=>Float::INFINITY},
          'contribution' => {'type'=>'CodeableConcept', 'path'=>'Entry.contribution', 'min'=>0, 'max'=>Float::INFINITY, 'binding'=>{'strength'=>'extensible', 'uri'=>'http://hl7.org/fhir/ValueSet/citation-contribution'}},
          'notAnAuthor' => {'type'=>'boolean', 'path'=>'Entry.notAnAuthor', 'min'=>0, 'max'=>1},
          'correspondingAuthor' => {'type'=>'boolean', 'path'=>'Entry.correspondingAuthor', 'min'=>0, 'max'=>1},
          'listOrder' => {'type'=>'positiveInt', 'path'=>'Entry.listOrder', 'min'=>0, 'max'=>1}
        }

        class AffiliationInfo < FHIR::Model
          include FHIR::Hashable
          include FHIR::Json
          include FHIR::Xml

          METADATA = {
            'id' => {'type'=>'string', 'path'=>'AffiliationInfo.id', 'min'=>0, 'max'=>1},
            'extension' => {'type'=>'Extension', 'path'=>'AffiliationInfo.extension', 'min'=>0, 'max'=>Float::INFINITY},
            'modifierExtension' => {'type'=>'Extension', 'path'=>'AffiliationInfo.modifierExtension', 'min'=>0, 'max'=>Float::INFINITY},
            'affiliation' => {'type'=>'string', 'path'=>'AffiliationInfo.affiliation', 'min'=>0, 'max'=>1},
            'role' => {'type'=>'string', 'path'=>'AffiliationInfo.role', 'min'=>0, 'max'=>1},
            'identifier' => {'type'=>'Identifier', 'path'=>'AffiliationInfo.identifier', 'min'=>0, 'max'=>Float::INFINITY}
          }

          attr_accessor :id                # 0-1 string
          attr_accessor :extension         # 0-* [ Extension ]
          attr_accessor :modifierExtension # 0-* [ Extension ]
          attr_accessor :affiliation       # 0-1 string
          attr_accessor :role              # 0-1 string
          attr_accessor :identifier        # 0-* [ Identifier ]
        end

        attr_accessor :id                  # 0-1 string
        attr_accessor :extension           # 0-* [ Extension ]
        attr_accessor :modifierExtension   # 0-* [ Extension ]
        attr_accessor :name                # 0-1 HumanName
        attr_accessor :initials            # 0-1 string
        attr_accessor :collectiveName      # 0-1 string
        attr_accessor :identifier          # 0-* [ Identifier ]
        attr_accessor :affiliationInfo     # 0-* [ Citation::Contributorship::Entry::AffiliationInfo ]
        attr_accessor :address             # 0-* [ Address ]
        attr_accessor :telecom             # 0-* [ ContactPoint ]
        attr_accessor :contribution        # 0-* [ CodeableConcept ]
        attr_accessor :notAnAuthor         # 0-1 boolean
        attr_accessor :correspondingAuthor # 0-1 boolean
        attr_accessor :listOrder           # 0-1 positiveInt
      end

      class Summary < FHIR::Model
        include FHIR::Hashable
        include FHIR::Json
        include FHIR::Xml

        METADATA = {
          'id' => {'type'=>'string', 'path'=>'Summary.id', 'min'=>0, 'max'=>1},
          'extension' => {'type'=>'Extension', 'path'=>'Summary.extension', 'min'=>0, 'max'=>Float::INFINITY},
          'modifierExtension' => {'type'=>'Extension', 'path'=>'Summary.modifierExtension', 'min'=>0, 'max'=>Float::INFINITY},
          'type' => {'type'=>'CodeableConcept', 'path'=>'Summary.type', 'min'=>0, 'max'=>1, 'binding'=>{'strength'=>'extensible', 'uri'=>'http://hl7.org/fhir/ValueSet/contributor-summary-type'}},
          'style' => {'type'=>'CodeableConcept', 'path'=>'Summary.style', 'min'=>0, 'max'=>1, 'binding'=>{'strength'=>'extensible', 'uri'=>'http://hl7.org/fhir/ValueSet/contributor-summary-style'}},
          'source' => {'type'=>'CodeableConcept', 'path'=>'Summary.source', 'min'=>0, 'max'=>1, 'binding'=>{'strength'=>'extensible', 'uri'=>'http://hl7.org/fhir/ValueSet/contributor-summary-source'}},
          'value' => {'type'=>'markdown', 'path'=>'Summary.value', 'min'=>1, 'max'=>1}
        }

        attr_accessor :id                # 0-1 string
        attr_accessor :extension         # 0-* [ Extension ]
        attr_accessor :modifierExtension # 0-* [ Extension ]
        attr_accessor :type              # 0-1 CodeableConcept
        attr_accessor :style             # 0-1 CodeableConcept
        attr_accessor :source            # 0-1 CodeableConcept
        attr_accessor :value             # 1-1 markdown
      end

      attr_accessor :id                # 0-1 string
      attr_accessor :extension         # 0-* [ Extension ]
      attr_accessor :modifierExtension # 0-* [ Extension ]
      attr_accessor :complete          # 0-1 boolean
      attr_accessor :entry             # 0-* [ Citation::Contributorship::Entry ]
      attr_accessor :summary           # 0-* [ Citation::Contributorship::Summary ]
    end

    class PublicationForm < FHIR::Model
      include FHIR::Hashable
      include FHIR::Json
      include FHIR::Xml

      METADATA = {
        'id' => {'type'=>'string', 'path'=>'PublicationForm.id', 'min'=>0, 'max'=>1},
        'extension' => {'type'=>'Extension', 'path'=>'PublicationForm.extension', 'min'=>0, 'max'=>Float::INFINITY},
        'modifierExtension' => {'type'=>'Extension', 'path'=>'PublicationForm.modifierExtension', 'min'=>0, 'max'=>Float::INFINITY},
        'publishingModel' => {'type'=>'CodeableConcept', 'path'=>'PublicationForm.publishingModel', 'min'=>0, 'max'=>1, 'binding'=>{'strength'=>'extensible', 'uri'=>'http://hl7.org/fhir/ValueSet/publishing-model-type'}},
        'publishedIn' => {'type'=>'Citation::PublicationForm::PublishedIn', 'path'=>'PublicationForm.publishedIn', 'min'=>0, 'max'=>1},
        'periodicRelease' => {'type'=>'Citation::PublicationForm::PeriodicRelease', 'path'=>'PublicationForm.periodicRelease', 'min'=>0, 'max'=>Float::INFINITY},
        'articleDate' => {'type'=>'dateTime', 'path'=>'PublicationForm.articleDate', 'min'=>0, 'max'=>1},
        'revisionDate' => {'type'=>'dateTime', 'path'=>'PublicationForm.revisionDate', 'min'=>0, 'max'=>1},
        'language' => {'valid_codes'=>{'urn:ietf:bcp:47'=>['ar', 'bn', 'cs', 'da', 'de', 'de-AT', 'de-CH', 'de-DE', 'el', 'en', 'en-AU', 'en-CA', 'en-GB', 'en-IN', 'en-NZ', 'en-SG', 'en-US', 'es', 'es-AR', 'es-ES', 'es-UY', 'fi', 'fr', 'fr-BE', 'fr-CH', 'fr-FR', 'fy', 'fy-NL', 'hi', 'hr', 'it', 'it-CH', 'it-IT', 'ja', 'ko', 'nl', 'nl-BE', 'nl-NL', 'no', 'no-NO', 'pa', 'pl', 'pt', 'pt-BR', 'ru', 'ru-RU', 'sr', 'sr-RS', 'sv', 'sv-SE', 'te', 'zh', 'zh-CN', 'zh-HK', 'zh-SG', 'zh-TW']}, 'type'=>'CodeableConcept', 'path'=>'PublicationForm.language', 'min'=>0, 'max'=>Float::INFINITY, 'binding'=>{'strength'=>'preferred', 'uri'=>'http://hl7.org/fhir/ValueSet/languages'}},
        'pageString' => {'type'=>'string', 'path'=>'PublicationForm.pageString', 'min'=>0, 'max'=>1},
        'firstPage' => {'type'=>'string', 'path'=>'PublicationForm.firstPage', 'min'=>0, 'max'=>1},
        'lastPage' => {'type'=>'string', 'path'=>'PublicationForm.lastPage', 'min'=>0, 'max'=>1},
        'pageCount' => {'type'=>'string', 'path'=>'PublicationForm.pageCount', 'min'=>0, 'max'=>1}
      }

      class PublishedIn < FHIR::Model
        include FHIR::Hashable
        include FHIR::Json
        include FHIR::Xml

        METADATA = {
          'id' => {'type'=>'string', 'path'=>'PublishedIn.id', 'min'=>0, 'max'=>1},
          'extension' => {'type'=>'Extension', 'path'=>'PublishedIn.extension', 'min'=>0, 'max'=>Float::INFINITY},
          'modifierExtension' => {'type'=>'Extension', 'path'=>'PublishedIn.modifierExtension', 'min'=>0, 'max'=>Float::INFINITY},
          'type' => {'type'=>'CodeableConcept', 'path'=>'PublishedIn.type', 'min'=>0, 'max'=>1, 'binding'=>{'strength'=>'extensible', 'uri'=>'http://hl7.org/fhir/ValueSet/published-in-type'}},
          'identifier' => {'type'=>'Identifier', 'path'=>'PublishedIn.identifier', 'min'=>0, 'max'=>Float::INFINITY},
          'title' => {'type'=>'string', 'path'=>'PublishedIn.title', 'min'=>0, 'max'=>1},
          'publisher' => {'type_profiles'=>['http://hl7.org/fhir/StructureDefinition/Organization'], 'type'=>'Reference', 'path'=>'PublishedIn.publisher', 'min'=>0, 'max'=>1},
          'publisherLocation' => {'type'=>'string', 'path'=>'PublishedIn.publisherLocation', 'min'=>0, 'max'=>1},
          'startDate' => {'type'=>'date', 'path'=>'PublishedIn.startDate', 'min'=>0, 'max'=>1}
        }

        attr_accessor :id                # 0-1 string
        attr_accessor :extension         # 0-* [ Extension ]
        attr_accessor :modifierExtension # 0-* [ Extension ]
        attr_accessor :type              # 0-1 CodeableConcept
        attr_accessor :identifier        # 0-* [ Identifier ]
        attr_accessor :title             # 0-1 string
        attr_accessor :publisher         # 0-1 Reference(Organization)
        attr_accessor :publisherLocation # 0-1 string
        attr_accessor :startDate         # 0-1 date
      end

      class PeriodicRelease < FHIR::Model
        include FHIR::Hashable
        include FHIR::Json
        include FHIR::Xml

        METADATA = {
          'id' => {'type'=>'string', 'path'=>'PeriodicRelease.id', 'min'=>0, 'max'=>1},
          'extension' => {'type'=>'Extension', 'path'=>'PeriodicRelease.extension', 'min'=>0, 'max'=>Float::INFINITY},
          'modifierExtension' => {'type'=>'Extension', 'path'=>'PeriodicRelease.modifierExtension', 'min'=>0, 'max'=>Float::INFINITY},
          'citedMedium' => {'type'=>'CodeableConcept', 'path'=>'PeriodicRelease.citedMedium', 'min'=>0, 'max'=>1, 'binding'=>{'strength'=>'extensible', 'uri'=>'http://hl7.org/fhir/ValueSet/journal-issue-medium'}},
          'volume' => {'type'=>'string', 'path'=>'PeriodicRelease.volume', 'min'=>0, 'max'=>1},
          'issue' => {'type'=>'string', 'path'=>'PeriodicRelease.issue', 'min'=>0, 'max'=>1},
          'dateOfPublication' => {'type'=>'Citation::PublicationForm::PeriodicRelease::DateOfPublication', 'path'=>'PeriodicRelease.dateOfPublication', 'min'=>0, 'max'=>1}
        }

        class DateOfPublication < FHIR::Model
          include FHIR::Hashable
          include FHIR::Json
          include FHIR::Xml

          METADATA = {
            'id' => {'type'=>'string', 'path'=>'DateOfPublication.id', 'min'=>0, 'max'=>1},
            'extension' => {'type'=>'Extension', 'path'=>'DateOfPublication.extension', 'min'=>0, 'max'=>Float::INFINITY},
            'modifierExtension' => {'type'=>'Extension', 'path'=>'DateOfPublication.modifierExtension', 'min'=>0, 'max'=>Float::INFINITY},
            'date' => {'type'=>'date', 'path'=>'DateOfPublication.date', 'min'=>0, 'max'=>1},
            'year' => {'type'=>'string', 'path'=>'DateOfPublication.year', 'min'=>0, 'max'=>1},
            'month' => {'type'=>'string', 'path'=>'DateOfPublication.month', 'min'=>0, 'max'=>1},
            'day' => {'type'=>'string', 'path'=>'DateOfPublication.day', 'min'=>0, 'max'=>1},
            'season' => {'type'=>'string', 'path'=>'DateOfPublication.season', 'min'=>0, 'max'=>1},
            'text' => {'type'=>'string', 'path'=>'DateOfPublication.text', 'min'=>0, 'max'=>1}
          }

          attr_accessor :id                # 0-1 string
          attr_accessor :extension         # 0-* [ Extension ]
          attr_accessor :modifierExtension # 0-* [ Extension ]
          attr_accessor :date              # 0-1 date
          attr_accessor :year              # 0-1 string
          attr_accessor :month             # 0-1 string
          attr_accessor :day               # 0-1 string
          attr_accessor :season            # 0-1 string
          attr_accessor :text              # 0-1 string
        end

        attr_accessor :id                # 0-1 string
        attr_accessor :extension         # 0-* [ Extension ]
        attr_accessor :modifierExtension # 0-* [ Extension ]
        attr_accessor :citedMedium       # 0-1 CodeableConcept
        attr_accessor :volume            # 0-1 string
        attr_accessor :issue             # 0-1 string
        attr_accessor :dateOfPublication # 0-1 Citation::PublicationForm::PeriodicRelease::DateOfPublication
      end

      attr_accessor :id                # 0-1 string
      attr_accessor :extension         # 0-* [ Extension ]
      attr_accessor :modifierExtension # 0-* [ Extension ]
      attr_accessor :publishingModel   # 0-1 CodeableConcept
      attr_accessor :publishedIn       # 0-1 Citation::PublicationForm::PublishedIn
      attr_accessor :periodicRelease   # 0-* [ Citation::PublicationForm::PeriodicRelease ]
      attr_accessor :articleDate       # 0-1 dateTime
      attr_accessor :revisionDate      # 0-1 dateTime
      attr_accessor :language          # 0-* [ CodeableConcept ]
      attr_accessor :pageString        # 0-1 string
      attr_accessor :firstPage         # 0-1 string
      attr_accessor :lastPage          # 0-1 string
      attr_accessor :pageCount         # 0-1 string
    end

    class KeywordList < FHIR::Model
      include FHIR::Hashable
      include FHIR::Json
      include FHIR::Xml

      METADATA = {
        'id' => {'type'=>'string', 'path'=>'KeywordList.id', 'min'=>0, 'max'=>1},
        'extension' => {'type'=>'Extension', 'path'=>'KeywordList.extension', 'min'=>0, 'max'=>Float::INFINITY},
        'modifierExtension' => {'type'=>'Extension', 'path'=>'KeywordList.modifierExtension', 'min'=>0, 'max'=>Float::INFINITY},
        'owner' => {'type'=>'string', 'path'=>'KeywordList.owner', 'min'=>0, 'max'=>1},
        'keyword' => {'type'=>'Citation::KeywordList::Keyword', 'path'=>'KeywordList.keyword', 'min'=>1, 'max'=>Float::INFINITY}
      }

      class Keyword < FHIR::Model
        include FHIR::Hashable
        include FHIR::Json
        include FHIR::Xml

        METADATA = {
          'id' => {'type'=>'string', 'path'=>'Keyword.id', 'min'=>0, 'max'=>1},
          'extension' => {'type'=>'Extension', 'path'=>'Keyword.extension', 'min'=>0, 'max'=>Float::INFINITY},
          'modifierExtension' => {'type'=>'Extension', 'path'=>'Keyword.modifierExtension', 'min'=>0, 'max'=>Float::INFINITY},
          'majorTopic' => {'type'=>'boolean', 'path'=>'Keyword.majorTopic', 'min'=>0, 'max'=>1},
          'value' => {'type'=>'string', 'path'=>'Keyword.value', 'min'=>1, 'max'=>1}
        }

        attr_accessor :id                # 0-1 string
        attr_accessor :extension         # 0-* [ Extension ]
        attr_accessor :modifierExtension # 0-* [ Extension ]
        attr_accessor :majorTopic        # 0-1 boolean
        attr_accessor :value             # 1-1 string
      end

      attr_accessor :id                # 0-1 string
      attr_accessor :extension         # 0-* [ Extension ]
      attr_accessor :modifierExtension # 0-* [ Extension ]
      attr_accessor :owner             # 0-1 string
      attr_accessor :keyword           # 1-* [ Citation::KeywordList::Keyword ]
    end

    class Medline < FHIR::Model
      include FHIR::Hashable
      include FHIR::Json
      include FHIR::Xml

      METADATA = {
        'id' => {'type'=>'string', 'path'=>'Medline.id', 'min'=>0, 'max'=>1},
        'extension' => {'type'=>'Extension', 'path'=>'Medline.extension', 'min'=>0, 'max'=>Float::INFINITY},
        'modifierExtension' => {'type'=>'Extension', 'path'=>'Medline.modifierExtension', 'min'=>0, 'max'=>Float::INFINITY},
        'state' => {'type'=>'code', 'path'=>'Medline.state', 'min'=>0, 'max'=>1, 'binding'=>{'strength'=>'required', 'uri'=>'http://hl7.org/fhir/ValueSet/medline-citation-status'}},
        'owner' => {'type'=>'code', 'path'=>'Medline.owner', 'min'=>0, 'max'=>1, 'binding'=>{'strength'=>'required', 'uri'=>'http://hl7.org/fhir/ValueSet/medline-citation-owner'}},
        'dateCreated' => {'type'=>'date', 'path'=>'Medline.dateCreated', 'min'=>0, 'max'=>1},
        'dateCompleted' => {'type'=>'date', 'path'=>'Medline.dateCompleted', 'min'=>0, 'max'=>1},
        'dateRevised' => {'type'=>'date', 'path'=>'Medline.dateRevised', 'min'=>0, 'max'=>1},
        'dateOnPubMed' => {'type'=>'Citation::Medline::DateOnPubMed', 'path'=>'Medline.dateOnPubMed', 'min'=>0, 'max'=>Float::INFINITY},
        'publicationState' => {'type'=>'code', 'path'=>'Medline.publicationState', 'min'=>0, 'max'=>1, 'binding'=>{'strength'=>'required', 'uri'=>'http://hl7.org/fhir/ValueSet/pubmed-pubstatus'}},
        'relatedArticle' => {'type'=>'Citation::Medline::RelatedArticle', 'path'=>'Medline.relatedArticle', 'min'=>0, 'max'=>Float::INFINITY}
      }

      class DateOnPubMed < FHIR::Model
        include FHIR::Hashable
        include FHIR::Json
        include FHIR::Xml

        METADATA = {
          'id' => {'type'=>'string', 'path'=>'DateOnPubMed.id', 'min'=>0, 'max'=>1},
          'extension' => {'type'=>'Extension', 'path'=>'DateOnPubMed.extension', 'min'=>0, 'max'=>Float::INFINITY},
          'modifierExtension' => {'type'=>'Extension', 'path'=>'DateOnPubMed.modifierExtension', 'min'=>0, 'max'=>Float::INFINITY},
          'publicationState' => {'type'=>'code', 'path'=>'DateOnPubMed.publicationState', 'min'=>0, 'max'=>1, 'binding'=>{'strength'=>'required', 'uri'=>'http://hl7.org/fhir/ValueSet/pubmed-pubstatus'}},
          'date' => {'type'=>'dateTime', 'path'=>'DateOnPubMed.date', 'min'=>0, 'max'=>1}
        }

        attr_accessor :id                # 0-1 string
        attr_accessor :extension         # 0-* [ Extension ]
        attr_accessor :modifierExtension # 0-* [ Extension ]
        attr_accessor :publicationState  # 0-1 code
        attr_accessor :date              # 0-1 dateTime
      end

      class RelatedArticle < FHIR::Model
        include FHIR::Hashable
        include FHIR::Json
        include FHIR::Xml

        METADATA = {
          'id' => {'type'=>'string', 'path'=>'RelatedArticle.id', 'min'=>0, 'max'=>1},
          'extension' => {'type'=>'Extension', 'path'=>'RelatedArticle.extension', 'min'=>0, 'max'=>Float::INFINITY},
          'modifierExtension' => {'type'=>'Extension', 'path'=>'RelatedArticle.modifierExtension', 'min'=>0, 'max'=>Float::INFINITY},
          'citationReference' => {'type_profiles'=>['http://hl7.org/fhir/StructureDefinition/Citation'], 'type'=>'Reference', 'path'=>'RelatedArticle.citationReference', 'min'=>0, 'max'=>1},
          'citationMarkdown' => {'type'=>'markdown', 'path'=>'RelatedArticle.citationMarkdown', 'min'=>0, 'max'=>1},
          'identifier' => {'type'=>'Identifier', 'path'=>'RelatedArticle.identifier', 'min'=>0, 'max'=>Float::INFINITY}
        }

        attr_accessor :id                # 0-1 string
        attr_accessor :extension         # 0-* [ Extension ]
        attr_accessor :modifierExtension # 0-* [ Extension ]
        attr_accessor :citationReference # 0-1 Reference(Citation)
        attr_accessor :citationMarkdown  # 0-1 markdown
        attr_accessor :identifier        # 0-* [ Identifier ]
      end

      attr_accessor :id                # 0-1 string
      attr_accessor :extension         # 0-* [ Extension ]
      attr_accessor :modifierExtension # 0-* [ Extension ]
      attr_accessor :state             # 0-1 code
      attr_accessor :owner             # 0-1 code
      attr_accessor :dateCreated       # 0-1 date
      attr_accessor :dateCompleted     # 0-1 date
      attr_accessor :dateRevised       # 0-1 date
      attr_accessor :dateOnPubMed      # 0-* [ Citation::Medline::DateOnPubMed ]
      attr_accessor :publicationState  # 0-1 code
      attr_accessor :relatedArticle    # 0-* [ Citation::Medline::RelatedArticle ]
    end

    attr_accessor :id                # 0-1 id
    attr_accessor :meta              # 0-1 Meta
    attr_accessor :implicitRules     # 0-1 uri
    attr_accessor :language          # 0-1 code
    attr_accessor :text              # 0-1 Narrative
    attr_accessor :contained         # 0-* [ Resource ]
    attr_accessor :extension         # 0-* [ Extension ]
    attr_accessor :modifierExtension # 0-* [ Extension ]
    attr_accessor :url               # 0-1 uri
    attr_accessor :identifier        # 0-* [ Identifier ]
    attr_accessor :relatedIdentifier # 0-* [ Identifier ]
    attr_accessor :version           # 0-1 string
    attr_accessor :name              # 0-1 string
    attr_accessor :title             # 0-1 string
    attr_accessor :status            # 1-1 code
    attr_accessor :experimental      # 0-1 boolean
    attr_accessor :date              # 0-1 dateTime
    attr_accessor :publisher         # 0-1 string
    attr_accessor :contact           # 0-* [ ContactDetail ]
    attr_accessor :description       # 0-1 markdown
    attr_accessor :useContext        # 0-* [ UsageContext ]
    attr_accessor :jurisdiction      # 0-* [ CodeableConcept ]
    attr_accessor :purpose           # 0-1 markdown
    attr_accessor :approvalDate      # 0-1 date
    attr_accessor :lastReviewDate    # 0-1 date
    attr_accessor :effectivePeriod   # 0-1 Period
    attr_accessor :summary           # 0-* [ Citation::Summary ]
    attr_accessor :dateCited         # 0-1 dateTime
    attr_accessor :variantCitation   # 0-1 Citation::VariantCitation
    attr_accessor :articleTitle      # 0-* [ Citation::ArticleTitle ]
    attr_accessor :webLocation       # 0-* [ Citation::WebLocation ]
    attr_accessor :abstract          # 0-* [ Citation::Abstract ]
    attr_accessor :contributorship   # 0-1 Citation::Contributorship
    attr_accessor :publicationForm   # 0-* [ Citation::PublicationForm ]
    attr_accessor :classifier        # 0-* [ CodeableConcept ]
    attr_accessor :keywordList       # 0-* [ Citation::KeywordList ]
    attr_accessor :relatedArtifact   # 0-* [ RelatedArtifact ]
    attr_accessor :note              # 0-* [ Annotation ]
    attr_accessor :medline           # 0-1 Citation::Medline

    def resourceType
      'Citation'
    end
  end
end