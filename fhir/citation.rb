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
      'copyright' => {'type'=>'markdown', 'path'=>'Citation.copyright', 'min'=>0, 'max'=>1},
      'approvalDate' => {'type'=>'date', 'path'=>'Citation.approvalDate', 'min'=>0, 'max'=>1},
      'lastReviewDate' => {'type'=>'date', 'path'=>'Citation.lastReviewDate', 'min'=>0, 'max'=>1},
      'effectivePeriod' => {'type'=>'Period', 'path'=>'Citation.effectivePeriod', 'min'=>0, 'max'=>1},
      'author' => {'type'=>'ContactDetail', 'path'=>'Citation.author', 'min'=>0, 'max'=>Float::INFINITY},
      'editor' => {'type'=>'ContactDetail', 'path'=>'Citation.editor', 'min'=>0, 'max'=>Float::INFINITY},
      'reviewer' => {'type'=>'ContactDetail', 'path'=>'Citation.reviewer', 'min'=>0, 'max'=>Float::INFINITY},
      'endorser' => {'type'=>'ContactDetail', 'path'=>'Citation.endorser', 'min'=>0, 'max'=>Float::INFINITY},
      'summary' => {'type'=>'Citation::Summary', 'path'=>'Citation.summary', 'min'=>0, 'max'=>Float::INFINITY},
      'classification' => {'type'=>'Citation::Classification', 'path'=>'Citation.classification', 'min'=>0, 'max'=>Float::INFINITY},
      'note' => {'type'=>'Annotation', 'path'=>'Citation.note', 'min'=>0, 'max'=>Float::INFINITY},
      'currentState' => {'type'=>'CodeableConcept', 'path'=>'Citation.currentState', 'min'=>0, 'max'=>Float::INFINITY, 'binding'=>{'strength'=>'example', 'uri'=>'http://hl7.org/fhir/ValueSet/citation-status-type'}},
      'statusDate' => {'type'=>'Citation::StatusDate', 'path'=>'Citation.statusDate', 'min'=>0, 'max'=>Float::INFINITY},
      'relatedArtifact' => {'type'=>'RelatedArtifact', 'path'=>'Citation.relatedArtifact', 'min'=>0, 'max'=>Float::INFINITY},
      'citedArtifact' => {'type'=>'Citation::CitedArtifact', 'path'=>'Citation.citedArtifact', 'min'=>0, 'max'=>1}
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

    class Classification < FHIR::Model
      include FHIR::Hashable
      include FHIR::Json
      include FHIR::Xml

      METADATA = {
        'id' => {'type'=>'string', 'path'=>'Classification.id', 'min'=>0, 'max'=>1},
        'extension' => {'type'=>'Extension', 'path'=>'Classification.extension', 'min'=>0, 'max'=>Float::INFINITY},
        'modifierExtension' => {'type'=>'Extension', 'path'=>'Classification.modifierExtension', 'min'=>0, 'max'=>Float::INFINITY},
        'type' => {'type'=>'CodeableConcept', 'path'=>'Classification.type', 'min'=>0, 'max'=>1, 'binding'=>{'strength'=>'extensible', 'uri'=>'http://hl7.org/fhir/ValueSet/citation-classification-type'}},
        'classifier' => {'type'=>'CodeableConcept', 'path'=>'Classification.classifier', 'min'=>0, 'max'=>Float::INFINITY, 'binding'=>{'strength'=>'example', 'uri'=>'http://hl7.org/fhir/ValueSet/citation-artifact-classifier'}}
      }

      attr_accessor :id                # 0-1 string
      attr_accessor :extension         # 0-* [ Extension ]
      attr_accessor :modifierExtension # 0-* [ Extension ]
      attr_accessor :type              # 0-1 CodeableConcept
      attr_accessor :classifier        # 0-* [ CodeableConcept ]
    end

    class StatusDate < FHIR::Model
      include FHIR::Hashable
      include FHIR::Json
      include FHIR::Xml

      METADATA = {
        'id' => {'type'=>'string', 'path'=>'StatusDate.id', 'min'=>0, 'max'=>1},
        'extension' => {'type'=>'Extension', 'path'=>'StatusDate.extension', 'min'=>0, 'max'=>Float::INFINITY},
        'modifierExtension' => {'type'=>'Extension', 'path'=>'StatusDate.modifierExtension', 'min'=>0, 'max'=>Float::INFINITY},
        'activity' => {'type'=>'CodeableConcept', 'path'=>'StatusDate.activity', 'min'=>1, 'max'=>1, 'binding'=>{'strength'=>'example', 'uri'=>'http://hl7.org/fhir/ValueSet/citation-status-type'}},
        'actual' => {'type'=>'boolean', 'path'=>'StatusDate.actual', 'min'=>0, 'max'=>1},
        'period' => {'type'=>'Period', 'path'=>'StatusDate.period', 'min'=>1, 'max'=>1}
      }

      attr_accessor :id                # 0-1 string
      attr_accessor :extension         # 0-* [ Extension ]
      attr_accessor :modifierExtension # 0-* [ Extension ]
      attr_accessor :activity          # 1-1 CodeableConcept
      attr_accessor :actual            # 0-1 boolean
      attr_accessor :period            # 1-1 Period
    end

    class CitedArtifact < FHIR::Model
      include FHIR::Hashable
      include FHIR::Json
      include FHIR::Xml

      METADATA = {
        'id' => {'type'=>'string', 'path'=>'CitedArtifact.id', 'min'=>0, 'max'=>1},
        'extension' => {'type'=>'Extension', 'path'=>'CitedArtifact.extension', 'min'=>0, 'max'=>Float::INFINITY},
        'modifierExtension' => {'type'=>'Extension', 'path'=>'CitedArtifact.modifierExtension', 'min'=>0, 'max'=>Float::INFINITY},
        'identifier' => {'type'=>'Identifier', 'path'=>'CitedArtifact.identifier', 'min'=>0, 'max'=>Float::INFINITY},
        'relatedIdentifier' => {'type'=>'Identifier', 'path'=>'CitedArtifact.relatedIdentifier', 'min'=>0, 'max'=>Float::INFINITY},
        'dateAccessed' => {'type'=>'dateTime', 'path'=>'CitedArtifact.dateAccessed', 'min'=>0, 'max'=>1},
        'version' => {'type'=>'Citation::CitedArtifact::Version', 'path'=>'CitedArtifact.version', 'min'=>0, 'max'=>1},
        'currentState' => {'type'=>'CodeableConcept', 'path'=>'CitedArtifact.currentState', 'min'=>0, 'max'=>Float::INFINITY, 'binding'=>{'strength'=>'extensible', 'uri'=>'http://hl7.org/fhir/ValueSet/cited-artifact-status-type'}},
        'statusDate' => {'type'=>'Citation::CitedArtifact::StatusDate', 'path'=>'CitedArtifact.statusDate', 'min'=>0, 'max'=>Float::INFINITY},
        'title' => {'type'=>'Citation::CitedArtifact::Title', 'path'=>'CitedArtifact.title', 'min'=>0, 'max'=>Float::INFINITY},
        'abstract' => {'type'=>'Citation::CitedArtifact::Abstract', 'path'=>'CitedArtifact.abstract', 'min'=>0, 'max'=>Float::INFINITY},
        'part' => {'type'=>'Citation::CitedArtifact::Part', 'path'=>'CitedArtifact.part', 'min'=>0, 'max'=>1},
        'relatesTo' => {'type'=>'RelatedArtifact', 'path'=>'CitedArtifact.relatesTo', 'min'=>0, 'max'=>Float::INFINITY},
        'publicationForm' => {'type'=>'Citation::CitedArtifact::PublicationForm', 'path'=>'CitedArtifact.publicationForm', 'min'=>0, 'max'=>Float::INFINITY},
        'webLocation' => {'type'=>'Citation::CitedArtifact::WebLocation', 'path'=>'CitedArtifact.webLocation', 'min'=>0, 'max'=>Float::INFINITY},
        'classification' => {'type'=>'Citation::CitedArtifact::Classification', 'path'=>'CitedArtifact.classification', 'min'=>0, 'max'=>Float::INFINITY},
        'contributorship' => {'type'=>'Citation::CitedArtifact::Contributorship', 'path'=>'CitedArtifact.contributorship', 'min'=>0, 'max'=>1},
        'note' => {'type'=>'Annotation', 'path'=>'CitedArtifact.note', 'min'=>0, 'max'=>Float::INFINITY}
      }

      class Version < FHIR::Model
        include FHIR::Hashable
        include FHIR::Json
        include FHIR::Xml

        METADATA = {
          'id' => {'type'=>'string', 'path'=>'Version.id', 'min'=>0, 'max'=>1},
          'extension' => {'type'=>'Extension', 'path'=>'Version.extension', 'min'=>0, 'max'=>Float::INFINITY},
          'modifierExtension' => {'type'=>'Extension', 'path'=>'Version.modifierExtension', 'min'=>0, 'max'=>Float::INFINITY},
          'value' => {'type'=>'string', 'path'=>'Version.value', 'min'=>1, 'max'=>1},
          'baseCitation' => {'type_profiles'=>['http://hl7.org/fhir/StructureDefinition/Citation'], 'type'=>'Reference', 'path'=>'Version.baseCitation', 'min'=>0, 'max'=>1}
        }

        attr_accessor :id                # 0-1 string
        attr_accessor :extension         # 0-* [ Extension ]
        attr_accessor :modifierExtension # 0-* [ Extension ]
        attr_accessor :value             # 1-1 string
        attr_accessor :baseCitation      # 0-1 Reference(Citation)
      end

      class StatusDate < FHIR::Model
        include FHIR::Hashable
        include FHIR::Json
        include FHIR::Xml

        METADATA = {
          'id' => {'type'=>'string', 'path'=>'StatusDate.id', 'min'=>0, 'max'=>1},
          'extension' => {'type'=>'Extension', 'path'=>'StatusDate.extension', 'min'=>0, 'max'=>Float::INFINITY},
          'modifierExtension' => {'type'=>'Extension', 'path'=>'StatusDate.modifierExtension', 'min'=>0, 'max'=>Float::INFINITY},
          'activity' => {'type'=>'CodeableConcept', 'path'=>'StatusDate.activity', 'min'=>1, 'max'=>1, 'binding'=>{'strength'=>'extensible', 'uri'=>'http://hl7.org/fhir/ValueSet/cited-artifact-status-type'}},
          'actual' => {'type'=>'boolean', 'path'=>'StatusDate.actual', 'min'=>0, 'max'=>1},
          'period' => {'type'=>'Period', 'path'=>'StatusDate.period', 'min'=>1, 'max'=>1}
        }

        attr_accessor :id                # 0-1 string
        attr_accessor :extension         # 0-* [ Extension ]
        attr_accessor :modifierExtension # 0-* [ Extension ]
        attr_accessor :activity          # 1-1 CodeableConcept
        attr_accessor :actual            # 0-1 boolean
        attr_accessor :period            # 1-1 Period
      end

      class Title < FHIR::Model
        include FHIR::Hashable
        include FHIR::Json
        include FHIR::Xml

        METADATA = {
          'id' => {'type'=>'string', 'path'=>'Title.id', 'min'=>0, 'max'=>1},
          'extension' => {'type'=>'Extension', 'path'=>'Title.extension', 'min'=>0, 'max'=>Float::INFINITY},
          'modifierExtension' => {'type'=>'Extension', 'path'=>'Title.modifierExtension', 'min'=>0, 'max'=>Float::INFINITY},
          'type' => {'type'=>'CodeableConcept', 'path'=>'Title.type', 'min'=>0, 'max'=>Float::INFINITY, 'binding'=>{'strength'=>'extensible', 'uri'=>'http://hl7.org/fhir/ValueSet/title-type'}},
          'language' => {'valid_codes'=>{'urn:ietf:bcp:47'=>['ar', 'bn', 'cs', 'da', 'de', 'de-AT', 'de-CH', 'de-DE', 'el', 'en', 'en-AU', 'en-CA', 'en-GB', 'en-IN', 'en-NZ', 'en-SG', 'en-US', 'es', 'es-AR', 'es-ES', 'es-UY', 'fi', 'fr', 'fr-BE', 'fr-CH', 'fr-FR', 'fy', 'fy-NL', 'hi', 'hr', 'it', 'it-CH', 'it-IT', 'ja', 'ko', 'nl', 'nl-BE', 'nl-NL', 'no', 'no-NO', 'pa', 'pl', 'pt', 'pt-BR', 'ru', 'ru-RU', 'sr', 'sr-RS', 'sv', 'sv-SE', 'te', 'zh', 'zh-CN', 'zh-HK', 'zh-SG', 'zh-TW']}, 'type'=>'CodeableConcept', 'path'=>'Title.language', 'min'=>0, 'max'=>1, 'binding'=>{'strength'=>'preferred', 'uri'=>'http://hl7.org/fhir/ValueSet/languages'}},
          'text' => {'type'=>'markdown', 'path'=>'Title.text', 'min'=>1, 'max'=>1}
        }

        attr_accessor :id                # 0-1 string
        attr_accessor :extension         # 0-* [ Extension ]
        attr_accessor :modifierExtension # 0-* [ Extension ]
        attr_accessor :type              # 0-* [ CodeableConcept ]
        attr_accessor :language          # 0-1 CodeableConcept
        attr_accessor :text              # 1-1 markdown
      end

      class Abstract < FHIR::Model
        include FHIR::Hashable
        include FHIR::Json
        include FHIR::Xml

        METADATA = {
          'id' => {'type'=>'string', 'path'=>'Abstract.id', 'min'=>0, 'max'=>1},
          'extension' => {'type'=>'Extension', 'path'=>'Abstract.extension', 'min'=>0, 'max'=>Float::INFINITY},
          'modifierExtension' => {'type'=>'Extension', 'path'=>'Abstract.modifierExtension', 'min'=>0, 'max'=>Float::INFINITY},
          'type' => {'type'=>'CodeableConcept', 'path'=>'Abstract.type', 'min'=>0, 'max'=>1, 'binding'=>{'strength'=>'extensible', 'uri'=>'http://hl7.org/fhir/ValueSet/cited-artifact-abstract-type'}},
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

      class Part < FHIR::Model
        include FHIR::Hashable
        include FHIR::Json
        include FHIR::Xml

        METADATA = {
          'id' => {'type'=>'string', 'path'=>'Part.id', 'min'=>0, 'max'=>1},
          'extension' => {'type'=>'Extension', 'path'=>'Part.extension', 'min'=>0, 'max'=>Float::INFINITY},
          'modifierExtension' => {'type'=>'Extension', 'path'=>'Part.modifierExtension', 'min'=>0, 'max'=>Float::INFINITY},
          'type' => {'type'=>'CodeableConcept', 'path'=>'Part.type', 'min'=>0, 'max'=>1, 'binding'=>{'strength'=>'extensible', 'uri'=>'http://hl7.org/fhir/ValueSet/cited-artifact-part-type'}},
          'value' => {'type'=>'string', 'path'=>'Part.value', 'min'=>0, 'max'=>1},
          'baseCitation' => {'type_profiles'=>['http://hl7.org/fhir/StructureDefinition/Citation'], 'type'=>'Reference', 'path'=>'Part.baseCitation', 'min'=>0, 'max'=>1}
        }

        attr_accessor :id                # 0-1 string
        attr_accessor :extension         # 0-* [ Extension ]
        attr_accessor :modifierExtension # 0-* [ Extension ]
        attr_accessor :type              # 0-1 CodeableConcept
        attr_accessor :value             # 0-1 string
        attr_accessor :baseCitation      # 0-1 Reference(Citation)
      end

      class PublicationForm < FHIR::Model
        include FHIR::Hashable
        include FHIR::Json
        include FHIR::Xml

        METADATA = {
          'id' => {'type'=>'string', 'path'=>'PublicationForm.id', 'min'=>0, 'max'=>1},
          'extension' => {'type'=>'Extension', 'path'=>'PublicationForm.extension', 'min'=>0, 'max'=>Float::INFINITY},
          'modifierExtension' => {'type'=>'Extension', 'path'=>'PublicationForm.modifierExtension', 'min'=>0, 'max'=>Float::INFINITY},
          'publishedIn' => {'type'=>'Citation::CitedArtifact::PublicationForm::PublishedIn', 'path'=>'PublicationForm.publishedIn', 'min'=>0, 'max'=>1},
          'periodicRelease' => {'type'=>'Citation::CitedArtifact::PublicationForm::PeriodicRelease', 'path'=>'PublicationForm.periodicRelease', 'min'=>0, 'max'=>1},
          'articleDate' => {'type'=>'dateTime', 'path'=>'PublicationForm.articleDate', 'min'=>0, 'max'=>1},
          'lastRevisionDate' => {'type'=>'dateTime', 'path'=>'PublicationForm.lastRevisionDate', 'min'=>0, 'max'=>1},
          'language' => {'valid_codes'=>{'urn:ietf:bcp:47'=>['ar', 'bn', 'cs', 'da', 'de', 'de-AT', 'de-CH', 'de-DE', 'el', 'en', 'en-AU', 'en-CA', 'en-GB', 'en-IN', 'en-NZ', 'en-SG', 'en-US', 'es', 'es-AR', 'es-ES', 'es-UY', 'fi', 'fr', 'fr-BE', 'fr-CH', 'fr-FR', 'fy', 'fy-NL', 'hi', 'hr', 'it', 'it-CH', 'it-IT', 'ja', 'ko', 'nl', 'nl-BE', 'nl-NL', 'no', 'no-NO', 'pa', 'pl', 'pt', 'pt-BR', 'ru', 'ru-RU', 'sr', 'sr-RS', 'sv', 'sv-SE', 'te', 'zh', 'zh-CN', 'zh-HK', 'zh-SG', 'zh-TW']}, 'type'=>'CodeableConcept', 'path'=>'PublicationForm.language', 'min'=>0, 'max'=>Float::INFINITY, 'binding'=>{'strength'=>'preferred', 'uri'=>'http://hl7.org/fhir/ValueSet/languages'}},
          'accessionNumber' => {'type'=>'string', 'path'=>'PublicationForm.accessionNumber', 'min'=>0, 'max'=>1},
          'pageString' => {'type'=>'string', 'path'=>'PublicationForm.pageString', 'min'=>0, 'max'=>1},
          'firstPage' => {'type'=>'string', 'path'=>'PublicationForm.firstPage', 'min'=>0, 'max'=>1},
          'lastPage' => {'type'=>'string', 'path'=>'PublicationForm.lastPage', 'min'=>0, 'max'=>1},
          'pageCount' => {'type'=>'string', 'path'=>'PublicationForm.pageCount', 'min'=>0, 'max'=>1},
          'copyright' => {'type'=>'markdown', 'path'=>'PublicationForm.copyright', 'min'=>0, 'max'=>1}
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
            'publisherLocation' => {'type'=>'string', 'path'=>'PublishedIn.publisherLocation', 'min'=>0, 'max'=>1}
          }

          attr_accessor :id                # 0-1 string
          attr_accessor :extension         # 0-* [ Extension ]
          attr_accessor :modifierExtension # 0-* [ Extension ]
          attr_accessor :type              # 0-1 CodeableConcept
          attr_accessor :identifier        # 0-* [ Identifier ]
          attr_accessor :title             # 0-1 string
          attr_accessor :publisher         # 0-1 Reference(Organization)
          attr_accessor :publisherLocation # 0-1 string
        end

        class PeriodicRelease < FHIR::Model
          include FHIR::Hashable
          include FHIR::Json
          include FHIR::Xml

          METADATA = {
            'id' => {'type'=>'string', 'path'=>'PeriodicRelease.id', 'min'=>0, 'max'=>1},
            'extension' => {'type'=>'Extension', 'path'=>'PeriodicRelease.extension', 'min'=>0, 'max'=>Float::INFINITY},
            'modifierExtension' => {'type'=>'Extension', 'path'=>'PeriodicRelease.modifierExtension', 'min'=>0, 'max'=>Float::INFINITY},
            'citedMedium' => {'type'=>'CodeableConcept', 'path'=>'PeriodicRelease.citedMedium', 'min'=>0, 'max'=>1, 'binding'=>{'strength'=>'extensible', 'uri'=>'http://hl7.org/fhir/ValueSet/cited-medium'}},
            'volume' => {'type'=>'string', 'path'=>'PeriodicRelease.volume', 'min'=>0, 'max'=>1},
            'issue' => {'type'=>'string', 'path'=>'PeriodicRelease.issue', 'min'=>0, 'max'=>1},
            'dateOfPublication' => {'type'=>'Citation::CitedArtifact::PublicationForm::PeriodicRelease::DateOfPublication', 'path'=>'PeriodicRelease.dateOfPublication', 'min'=>0, 'max'=>1}
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
          attr_accessor :dateOfPublication # 0-1 Citation::CitedArtifact::PublicationForm::PeriodicRelease::DateOfPublication
        end

        attr_accessor :id                # 0-1 string
        attr_accessor :extension         # 0-* [ Extension ]
        attr_accessor :modifierExtension # 0-* [ Extension ]
        attr_accessor :publishedIn       # 0-1 Citation::CitedArtifact::PublicationForm::PublishedIn
        attr_accessor :periodicRelease   # 0-1 Citation::CitedArtifact::PublicationForm::PeriodicRelease
        attr_accessor :articleDate       # 0-1 dateTime
        attr_accessor :lastRevisionDate  # 0-1 dateTime
        attr_accessor :language          # 0-* [ CodeableConcept ]
        attr_accessor :accessionNumber   # 0-1 string
        attr_accessor :pageString        # 0-1 string
        attr_accessor :firstPage         # 0-1 string
        attr_accessor :lastPage          # 0-1 string
        attr_accessor :pageCount         # 0-1 string
        attr_accessor :copyright         # 0-1 markdown
      end

      class WebLocation < FHIR::Model
        include FHIR::Hashable
        include FHIR::Json
        include FHIR::Xml

        METADATA = {
          'id' => {'type'=>'string', 'path'=>'WebLocation.id', 'min'=>0, 'max'=>1},
          'extension' => {'type'=>'Extension', 'path'=>'WebLocation.extension', 'min'=>0, 'max'=>Float::INFINITY},
          'modifierExtension' => {'type'=>'Extension', 'path'=>'WebLocation.modifierExtension', 'min'=>0, 'max'=>Float::INFINITY},
          'classifier' => {'type'=>'CodeableConcept', 'path'=>'WebLocation.classifier', 'min'=>0, 'max'=>Float::INFINITY, 'binding'=>{'strength'=>'extensible', 'uri'=>'http://hl7.org/fhir/ValueSet/artifact-url-classifier'}},
          'url' => {'type'=>'uri', 'path'=>'WebLocation.url', 'min'=>0, 'max'=>1}
        }

        attr_accessor :id                # 0-1 string
        attr_accessor :extension         # 0-* [ Extension ]
        attr_accessor :modifierExtension # 0-* [ Extension ]
        attr_accessor :classifier        # 0-* [ CodeableConcept ]
        attr_accessor :url               # 0-1 uri
      end

      class Classification < FHIR::Model
        include FHIR::Hashable
        include FHIR::Json
        include FHIR::Xml

        METADATA = {
          'id' => {'type'=>'string', 'path'=>'Classification.id', 'min'=>0, 'max'=>1},
          'extension' => {'type'=>'Extension', 'path'=>'Classification.extension', 'min'=>0, 'max'=>Float::INFINITY},
          'modifierExtension' => {'type'=>'Extension', 'path'=>'Classification.modifierExtension', 'min'=>0, 'max'=>Float::INFINITY},
          'type' => {'type'=>'CodeableConcept', 'path'=>'Classification.type', 'min'=>0, 'max'=>1, 'binding'=>{'strength'=>'extensible', 'uri'=>'http://hl7.org/fhir/ValueSet/cited-artifact-classification-type'}},
          'classifier' => {'type'=>'CodeableConcept', 'path'=>'Classification.classifier', 'min'=>0, 'max'=>Float::INFINITY, 'binding'=>{'strength'=>'example', 'uri'=>'http://hl7.org/fhir/ValueSet/citation-artifact-classifier'}},
          'artifactAssessment' => {'type_profiles'=>['http://hl7.org/fhir/StructureDefinition/ArtifactAssessment'], 'type'=>'Reference', 'path'=>'Classification.artifactAssessment', 'min'=>0, 'max'=>Float::INFINITY}
        }

        attr_accessor :id                 # 0-1 string
        attr_accessor :extension          # 0-* [ Extension ]
        attr_accessor :modifierExtension  # 0-* [ Extension ]
        attr_accessor :type               # 0-1 CodeableConcept
        attr_accessor :classifier         # 0-* [ CodeableConcept ]
        attr_accessor :artifactAssessment # 0-* [ Reference(ArtifactAssessment) ]
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
          'entry' => {'type'=>'Citation::CitedArtifact::Contributorship::Entry', 'path'=>'Contributorship.entry', 'min'=>0, 'max'=>Float::INFINITY},
          'summary' => {'type'=>'Citation::CitedArtifact::Contributorship::Summary', 'path'=>'Contributorship.summary', 'min'=>0, 'max'=>Float::INFINITY}
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
            'affiliationInfo' => {'type'=>'Citation::CitedArtifact::Contributorship::Entry::AffiliationInfo', 'path'=>'Entry.affiliationInfo', 'min'=>0, 'max'=>Float::INFINITY},
            'address' => {'type'=>'Address', 'path'=>'Entry.address', 'min'=>0, 'max'=>Float::INFINITY},
            'telecom' => {'type'=>'ContactPoint', 'path'=>'Entry.telecom', 'min'=>0, 'max'=>Float::INFINITY},
            'contributionType' => {'type'=>'CodeableConcept', 'path'=>'Entry.contributionType', 'min'=>0, 'max'=>Float::INFINITY, 'binding'=>{'strength'=>'extensible', 'uri'=>'http://hl7.org/fhir/ValueSet/artifact-contribution-type'}},
            'role' => {'type'=>'CodeableConcept', 'path'=>'Entry.role', 'min'=>0, 'max'=>1, 'binding'=>{'strength'=>'extensible', 'uri'=>'http://hl7.org/fhir/ValueSet/contributor-role'}},
            'contributionInstance' => {'type'=>'Citation::CitedArtifact::Contributorship::Entry::ContributionInstance', 'path'=>'Entry.contributionInstance', 'min'=>0, 'max'=>Float::INFINITY},
            'correspondingContact' => {'type'=>'boolean', 'path'=>'Entry.correspondingContact', 'min'=>0, 'max'=>1},
            'rankingOrder' => {'type'=>'positiveInt', 'path'=>'Entry.rankingOrder', 'min'=>0, 'max'=>1}
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

          class ContributionInstance < FHIR::Model
            include FHIR::Hashable
            include FHIR::Json
            include FHIR::Xml

            METADATA = {
              'id' => {'type'=>'string', 'path'=>'ContributionInstance.id', 'min'=>0, 'max'=>1},
              'extension' => {'type'=>'Extension', 'path'=>'ContributionInstance.extension', 'min'=>0, 'max'=>Float::INFINITY},
              'modifierExtension' => {'type'=>'Extension', 'path'=>'ContributionInstance.modifierExtension', 'min'=>0, 'max'=>Float::INFINITY},
              'type' => {'type'=>'CodeableConcept', 'path'=>'ContributionInstance.type', 'min'=>1, 'max'=>1, 'binding'=>{'strength'=>'extensible', 'uri'=>'http://hl7.org/fhir/ValueSet/artifact-contribution-instance-type'}},
              'time' => {'type'=>'dateTime', 'path'=>'ContributionInstance.time', 'min'=>0, 'max'=>1}
            }

            attr_accessor :id                # 0-1 string
            attr_accessor :extension         # 0-* [ Extension ]
            attr_accessor :modifierExtension # 0-* [ Extension ]
            attr_accessor :type              # 1-1 CodeableConcept
            attr_accessor :time              # 0-1 dateTime
          end

          attr_accessor :id                   # 0-1 string
          attr_accessor :extension            # 0-* [ Extension ]
          attr_accessor :modifierExtension    # 0-* [ Extension ]
          attr_accessor :name                 # 0-1 HumanName
          attr_accessor :initials             # 0-1 string
          attr_accessor :collectiveName       # 0-1 string
          attr_accessor :identifier           # 0-* [ Identifier ]
          attr_accessor :affiliationInfo      # 0-* [ Citation::CitedArtifact::Contributorship::Entry::AffiliationInfo ]
          attr_accessor :address              # 0-* [ Address ]
          attr_accessor :telecom              # 0-* [ ContactPoint ]
          attr_accessor :contributionType     # 0-* [ CodeableConcept ]
          attr_accessor :role                 # 0-1 CodeableConcept
          attr_accessor :contributionInstance # 0-* [ Citation::CitedArtifact::Contributorship::Entry::ContributionInstance ]
          attr_accessor :correspondingContact # 0-1 boolean
          attr_accessor :rankingOrder         # 0-1 positiveInt
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
        attr_accessor :entry             # 0-* [ Citation::CitedArtifact::Contributorship::Entry ]
        attr_accessor :summary           # 0-* [ Citation::CitedArtifact::Contributorship::Summary ]
      end

      attr_accessor :id                # 0-1 string
      attr_accessor :extension         # 0-* [ Extension ]
      attr_accessor :modifierExtension # 0-* [ Extension ]
      attr_accessor :identifier        # 0-* [ Identifier ]
      attr_accessor :relatedIdentifier # 0-* [ Identifier ]
      attr_accessor :dateAccessed      # 0-1 dateTime
      attr_accessor :version           # 0-1 Citation::CitedArtifact::Version
      attr_accessor :currentState      # 0-* [ CodeableConcept ]
      attr_accessor :statusDate        # 0-* [ Citation::CitedArtifact::StatusDate ]
      attr_accessor :title             # 0-* [ Citation::CitedArtifact::Title ]
      attr_accessor :abstract          # 0-* [ Citation::CitedArtifact::Abstract ]
      attr_accessor :part              # 0-1 Citation::CitedArtifact::Part
      attr_accessor :relatesTo         # 0-* [ RelatedArtifact ]
      attr_accessor :publicationForm   # 0-* [ Citation::CitedArtifact::PublicationForm ]
      attr_accessor :webLocation       # 0-* [ Citation::CitedArtifact::WebLocation ]
      attr_accessor :classification    # 0-* [ Citation::CitedArtifact::Classification ]
      attr_accessor :contributorship   # 0-1 Citation::CitedArtifact::Contributorship
      attr_accessor :note              # 0-* [ Annotation ]
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
    attr_accessor :copyright         # 0-1 markdown
    attr_accessor :approvalDate      # 0-1 date
    attr_accessor :lastReviewDate    # 0-1 date
    attr_accessor :effectivePeriod   # 0-1 Period
    attr_accessor :author            # 0-* [ ContactDetail ]
    attr_accessor :editor            # 0-* [ ContactDetail ]
    attr_accessor :reviewer          # 0-* [ ContactDetail ]
    attr_accessor :endorser          # 0-* [ ContactDetail ]
    attr_accessor :summary           # 0-* [ Citation::Summary ]
    attr_accessor :classification    # 0-* [ Citation::Classification ]
    attr_accessor :note              # 0-* [ Annotation ]
    attr_accessor :currentState      # 0-* [ CodeableConcept ]
    attr_accessor :statusDate        # 0-* [ Citation::StatusDate ]
    attr_accessor :relatedArtifact   # 0-* [ RelatedArtifact ]
    attr_accessor :citedArtifact     # 0-1 Citation::CitedArtifact

    def resourceType
      'Citation'
    end
  end
end