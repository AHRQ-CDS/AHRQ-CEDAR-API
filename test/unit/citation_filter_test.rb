# frozen_string_literal: true

require 'warning'
require_relative '../test_helper'
require_relative '../../database/models'
require_relative '../../fhir/fhir_code_systems'

describe CitationFilter do
  include Rack::Test::Methods
  include CedarApi::TestHelper

  before do
    Warning.ignore(/instance variable @\w+ not initialized/)
  end

  def assert_bundle(bundle, assert_total: true)
    refute_nil bundle
    assert bundle.is_a?(FHIR::Bundle)
    assert_equal 'searchset', bundle.type
    assert_equal bundle.total, bundle.entry.size if assert_total
    assert bundle.entry.size.positive?
  end

  def assert_paging(bundle, count, page)
    assert_equal(Artifact.count, bundle.total)
    assert_equal(count, bundle.entry.length)

    self_link = bundle.link&.find { |link| link.relation == 'self' }
    prev_link = bundle.link&.find { |link| link.relation == 'prev' }
    next_link = bundle.link&.find { |link| link.relation == 'next' }

    last_page = (bundle.total / count).ceil

    refute_nil self_link&.url
    assert_includes self_link.url, "page=#{page}"

    case page
    when 1
      assert_nil prev_link
      refute_nil next_link
    when last_page
      refute_nil prev_link
      assert_nil next_link
    else
      refute_nil prev_link
      refute_nil next_link
    end
  end

  describe 'parse FHIR datetime search' do
    it 'handles year only' do
      range = CitationFilter.get_fhir_datetime_range('2010')
      assert_equal(DateTime.parse('2010-01-01T00:00:00'), range[:start])
      assert_equal(DateTime.parse('2010-12-31T23:59:59'), range[:end])
    end

    it 'handles year and month only' do
      range = CitationFilter.get_fhir_datetime_range('2010-12')
      assert_equal(DateTime.parse('2010-12-01T00:00:00'), range[:start])
      assert_equal(DateTime.parse('2010-12-31T23:59:59'), range[:end])
    end

    it 'handles year, month and day only' do
      range = CitationFilter.get_fhir_datetime_range('2010-12-01')
      assert_equal(DateTime.parse('2010-12-01T00:00:00'), range[:start])
      assert_equal(DateTime.parse('2010-12-01T23:59:59'), range[:end])
    end

    it 'handles fully specified date time' do
      range = CitationFilter.get_fhir_datetime_range('2010-12-01T13:30:20')
      assert_equal(DateTime.parse('2010-12-01T13:30:20'), range[:start])
      assert_equal(DateTime.parse('2010-12-01T13:30:20'), range[:end])
    end

    it 'handles missing comparator' do
      search = CitationFilter.parse_fhir_datetime_search('2010')
      assert_equal(DateTime.parse('2010-01-01T00:00:00'), search[:start])
      assert_equal(DateTime.parse('2010-12-31T23:59:59'), search[:end])
      assert_equal('eq', search[:comparator])
    end

    it 'supports explicit comparator' do
      search = CitationFilter.parse_fhir_datetime_search('gt2010')
      assert_equal(DateTime.parse('2010-01-01T00:00:00'), search[:start])
      assert_equal(DateTime.parse('2010-12-31T23:59:59'), search[:end])
      assert_equal('gt', search[:comparator])
    end
  end

  describe 'find citation' do
    before do
      @artifact_base_url = 'http://localhost/fhir/Citation'
      @redirect_base_url = 'http://localhost/redirect'
      @request_url = 'http://example.com/fhir/Citation'
    end

    it 'supports search by _content' do
      expected = 'cancer'
      params = {
        '_content' => expected
      }

      bundle = CitationFilter.new(params: params, artifact_base_url: @artifact_base_url,
                                  redirect_base_url: @redirect_base_url,
                                  request_url: @request_url).citations

      assert_bundle(bundle)

      assert bundle.entry.all? do |entry|
        entry.resource.title.downcase.include?(expected) ||
          entry.resource.description.downcase.include?(expected)
      end
    end

    it 'includes related links' do
      expected = 'xyzzy'
      params = {
        '_content' => expected
      }

      bundle = CitationFilter.new(params: params, artifact_base_url: @artifact_base_url,
                                  redirect_base_url: @redirect_base_url,
                                  request_url: @request_url).citations

      refute_nil bundle
      assert bundle.is_a?(FHIR::Bundle)
      assert_equal 'searchset', bundle.type
      assert_empty bundle.entry
      assert_equal 0, bundle.total
      assert_equal 0, bundle.entry.size
      related_links = bundle.link.select { |link| link.relation == 'related' }
      assert_equal 2, related_links.size
    end

    it 'supports search for older artifacts' do
      cutoff_date = Date.new(2010, 6, 2)

      params = {
        '_lastUpdated' => "lt#{cutoff_date.strftime('%F')}"
      }

      bundle = CitationFilter.new(params: params, artifact_base_url: @artifact_base_url,
                                  redirect_base_url: @redirect_base_url,
                                  request_url: @request_url).citations

      assert_bundle(bundle)

      assert bundle.entry.all? do |entry|
        Date.new(entry.resource.date) < cutoff_date
      end
    end

    it 'supports search for newer artifacts' do
      cutoff_date = Date.new(2010, 6, 2)

      params = {
        '_lastUpdated' => "gt#{cutoff_date.strftime('%F')}"
      }

      bundle = CitationFilter.new(params: params, artifact_base_url: @artifact_base_url,
                                  redirect_base_url: @redirect_base_url,
                                  request_url: @request_url).citations

      assert_bundle(bundle)

      assert bundle.entry.all? do |entry|
        Date.new(entry.resource.date) > cutoff_date
      end
    end

    it 'supports search for article-date with correct implicit range' do
      cutoff_date = Date.new(2021, 1, 2)
      cutoff_date_start = cutoff_date.to_datetime
      cutoff_date_end = cutoff_date.to_datetime.next_day - 1.second

      params = {
        'article-date' => "le#{cutoff_date.strftime('%F')}"
      }

      bundle = CitationFilter.new(params: params, artifact_base_url: @artifact_base_url,
                                  redirect_base_url: @redirect_base_url,
                                  request_url: @request_url).citations

      assert_bundle(bundle)

      bundle.entry.each do |entry|
        entry.resource.citedArtifact.publicationForm.any? do |publication|
          if publication.articleDate.present?
            range = datestring_to_datetime_range(publication.articleDate)
            assert(range[0] < cutoff_date_start || range[1] <= cutoff_date_end)
          end
        end
      end

      params = {
        'article-date' => "gt#{cutoff_date.strftime('%F')}"
      }

      bundle = CitationFilter.new(params: params, artifact_base_url: @artifact_base_url,
                                  redirect_base_url: @redirect_base_url,
                                  request_url: @request_url).citations

      assert_bundle(bundle)

      bundle.entry.each do |entry|
        entry.resource.citedArtifact.publicationForm.any? do |publication|
          if publication.articleDate.present?
            range = datestring_to_datetime_range(publication.articleDate)
            assert(range[1] > cutoff_date_end)
          end
        end
      end

      params = {
        'article-date' => "eq#{cutoff_date.strftime('%F')}"
      }

      bundle = CitationFilter.new(params: params, artifact_base_url: @artifact_base_url,
                                  redirect_base_url: @redirect_base_url,
                                  request_url: @request_url).citations

      assert_bundle(bundle)

      bundle.entry.each do |entry|
        entry.resource.citedArtifact.publicationForm.any? do |publication|
          if publication.articleDate.present?
            range = datestring_to_datetime_range(publication.articleDate)
            assert(range[0] >= cutoff_date_start && range[1] <= cutoff_date_end)
          end
        end
      end
    end

    it 'supports search by presence/absence of article-date' do
      params = {
        'article-date:missing' => true
      }

      bundle = CitationFilter.new(params: params, artifact_base_url: @artifact_base_url,
                                  redirect_base_url: @redirect_base_url,
                                  request_url: @request_url).citations

      assert_bundle(bundle)

      assert bundle.entry.all? do |entry|
        entry.resource.citedArtifact.publicationForm.any? do |publication|
          publication.articleDate.nil?
        end
      end

      params['article-date:missing'] = false

      bundle = CitationFilter.new(params: params, artifact_base_url: @artifact_base_url,
                                  redirect_base_url: @redirect_base_url,
                                  request_url: @request_url).citations

      assert_bundle(bundle)

      assert bundle.entry.all? do |entry|
        entry.resource.citedArtifact.publicationForm.all? do |publication|
          !publication.articleDate.nil?
        end
      end
    end

    it 'supports search by title' do
      expected = 'diabetes'
      params = {
        'title' => expected
      }

      bundle = CitationFilter.new(params: params, artifact_base_url: @artifact_base_url,
                                  redirect_base_url: @redirect_base_url,
                                  request_url: @request_url).citations

      assert_bundle(bundle)

      assert bundle.entry.all? do |entry|
        entry.resource.title.downcase.start_with?(expected)
      end
    end

    it 'supports search by title with hyphens' do
      search_text = 'dia-betes'
      expected = 'diabetes'
      params = {
        'title' => search_text
      }

      bundle = CitationFilter.new(params: params, artifact_base_url: @artifact_base_url,
                                  redirect_base_url: @redirect_base_url,
                                  request_url: @request_url).citations

      assert_bundle(bundle)

      assert bundle.entry.all? do |entry|
        entry.resource.title.downcase.start_with?(expected)
      end
    end

    it 'supports search by title with multiple OR' do
      title_a = 'cancer'
      title_b = 'diabetes'
      params = {
        'title' => "#{title_a},#{title_b}"
      }

      bundle = CitationFilter.new(params: params, artifact_base_url: @artifact_base_url,
                                  redirect_base_url: @redirect_base_url,
                                  request_url: @request_url).citations

      assert_bundle(bundle)

      assert bundle.entry.all? do |entry|
        entry.resource.title.downcase.start_with?(title_a) ||
          entry.resource.title.downcase.start_with?(title_b)
      end
    end

    it 'supports search by title:contains' do
      expected = 'diabetes'
      params = {
        'title:contains' => expected
      }

      bundle = CitationFilter.new(params: params, artifact_base_url: @artifact_base_url,
                                  redirect_base_url: @redirect_base_url,
                                  request_url: @request_url).citations

      assert_bundle(bundle)

      assert bundle.entry.all? do |entry|
        entry.resource.title.downcase.include?(expected)
      end
    end

    it 'supports search by title:contains with hyphens' do
      search_text = 'bladder can-cer'
      expected = 'bladder cancer'
      params = {
        'title:contains' => search_text
      }

      bundle = CitationFilter.new(params: params, artifact_base_url: @artifact_base_url,
                                  redirect_base_url: @redirect_base_url,
                                  request_url: @request_url).citations

      assert_bundle(bundle)

      assert bundle.entry.all? do |entry|
        entry.resource.title.downcase.include?(expected)
      end
    end

    it 'supports search by title:contains with multiple AND' do
      expected = %w[bladder cancer]
      params = {
        'title:contains' => expected
      }

      bundle = CitationFilter.new(params: params, artifact_base_url: @artifact_base_url,
                                  redirect_base_url: @redirect_base_url,
                                  request_url: @request_url).citations

      assert_bundle(bundle)

      assert bundle.entry.all? do |entry|
        expected.all? { |word| entry.resource.title.downcase.include?(word) }
      end
    end

    it 'supports search by classification text' do
      expected = 'diabetes'
      params = {
        'classification:text' => expected
      }

      bundle = CitationFilter.new(params: params, artifact_base_url: @artifact_base_url,
                                  redirect_base_url: @redirect_base_url,
                                  request_url: @request_url).citations

      assert_bundle(bundle)

      assert bundle.entry.all? do |entry|
        entry.resource.citedArtifact.classification.any? do |classification|
          classification.classifier.any? { |classifier| classifier.text.downcase == expected }
        end
      end
    end

    it 'supports search by classification text with multiple OR' do
      expected = %w[diabetes Adult]
      params = {
        'classification:text' => expected.join(',')
      }

      bundle = CitationFilter.new(params: params, artifact_base_url: @artifact_base_url,
                                  redirect_base_url: @redirect_base_url,
                                  request_url: @request_url).citations

      assert_bundle(bundle)

      assert bundle.entry.all? do |entry|
        entry.resource.citedArtifact.classification.any? do |classification|
          classification.classifier.any? { |classifier| expected.include?(classifier.text.downcase) }
        end
      end
    end

    it 'supports search by classification system and code' do
      expected_system = FHIRCodeSystems::FHIR_CODE_SYSTEM_URLS['MSH']
      expected_code = 'D0001'
      params = {
        'classification' => "#{expected_system}|#{expected_code}"
      }

      bundle = CitationFilter.new(params: params, artifact_base_url: @artifact_base_url,
                                  redirect_base_url: @redirect_base_url,
                                  request_url: @request_url).citations

      assert_bundle(bundle)

      assert bundle.entry.all? do |entry|
        entry.resource.citedArtifact.classification.any? do |classification|
          classification.classifier.any? do |classifier|
            classifier.coding.any? { |coding| coding.system == expected_system && coding.code == expected_code }
          end
        end
      end
    end

    it 'supports search by classification code' do
      expected_code = 'D0001'
      params = {
        'classification' => expected_code
      }

      bundle = CitationFilter.new(params: params, artifact_base_url: @artifact_base_url,
                                  redirect_base_url: @redirect_base_url,
                                  request_url: @request_url).citations

      assert_bundle(bundle)

      assert bundle.entry.all? do |entry|
        entry.resource.citedArtifact.classification.any? do |classification|
          classification.classifier.any? do |classifier|
            classifier.coding.any? { |coding| coding.code == expected_code }
          end
        end
      end
    end

    it 'supports search by strength of recommendation' do
      expected_code = 'moderate'
      params = {
        'strength-of-recommendation' => expected_code
      }

      bundle = CitationFilter.new(params: params, artifact_base_url: @artifact_base_url,
                                  redirect_base_url: @redirect_base_url,
                                  request_url: @request_url).citations
      assert_bundle(bundle)

      assert bundle.entry.all? do |entry|
        entry.resource.citedArtifact.extension.any? do |ext|
          ext.url == 'http://cedar.arhq.gov/StructureDefinition/extension-strength-of-recommendation' &&
            ext.valueCodeableConcept.coding.any? { |coding| coding.code == expected_code }
        end
      end
    end

    it 'supports search by absence/presence of strength of recommendation' do
      params = {
        'strength-of-recommendation:missing' => true
      }

      bundle = CitationFilter.new(params: params, artifact_base_url: @artifact_base_url,
                                  redirect_base_url: @redirect_base_url,
                                  request_url: @request_url).citations

      assert_bundle(bundle)

      assert bundle.entry.all? do |entry|
        entry.resource.citedArtifact.extension.none? do |ext|
          ext.url == 'http://cedar.arhq.gov/StructureDefinition/extension-strength-of-recommendation'
        end
      end

      params['strength-of-recommendation:missing'] = false
      bundle = CitationFilter.new(params: params, artifact_base_url: @artifact_base_url,
                                  redirect_base_url: @redirect_base_url,
                                  request_url: @request_url).citations

      assert_bundle(bundle)

      assert bundle.entry.all? do |entry|
        entry.resource.citedArtifact.extension.all? do |ext|
          ext.url == 'http://cedar.arhq.gov/StructureDefinition/extension-strength-of-recommendation'
        end
      end
    end

    it 'supports search by quality of evidence' do
      expected_code = 'high'
      params = {
        'quality-of-evidence' => expected_code
      }

      bundle = CitationFilter.new(params: params, artifact_base_url: @artifact_base_url,
                                  redirect_base_url: @redirect_base_url,
                                  request_url: @request_url).citations

      assert_bundle(bundle)

      assert bundle.entry.all? do |entry|
        entry.resource.citedArtifact.extension.any? do |ext|
          ext.url == 'http://cedar.arhq.gov/StructureDefinition/extension-quality-of-evidence' &&
            ext.valueCodeableConcept.coding.any? { |coding| coding.code == expected_code }
        end
      end
    end

    it 'supports search by absence/presence of quality of evidence' do
      params = {
        'quality-of-evidence:missing' => true
      }

      bundle = CitationFilter.new(params: params, artifact_base_url: @artifact_base_url,
                                  redirect_base_url: @redirect_base_url,
                                  request_url: @request_url).citations

      assert_bundle(bundle)

      assert bundle.entry.all? do |entry|
        entry.resource.citedArtifact.extension.none? do |ext|
          ext.url == 'http://cedar.arhq.gov/StructureDefinition/extension-quality-of-evidence'
        end
      end

      params['quality-of-evidence:missing'] = false
      bundle = CitationFilter.new(params: params, artifact_base_url: @artifact_base_url,
                                  redirect_base_url: @redirect_base_url,
                                  request_url: @request_url).citations

      assert_bundle(bundle)

      assert bundle.entry.all? do |entry|
        entry.resource.citedArtifact.extension.all? do |ext|
          ext.url == 'http://cedar.arhq.gov/StructureDefinition/extension-quality-of-evidence'
        end
      end
    end

    it 'handles zero search results when searching by classification code' do
      expected_code = 'D002318'
      expected_bundle_total = 0
      params = {
        'classification' => expected_code
      }

      bundle = CitationFilter.new(params: params, artifact_base_url: @artifact_base_url,
                                  redirect_base_url: @redirect_base_url,
                                  request_url: @request_url).citations

      assert bundle.is_a?(FHIR::Bundle)
      assert_equal 'searchset', bundle.type
      assert_equal bundle.total, bundle.entry.size
      assert_equal bundle.total, expected_bundle_total
    end

    it 'supports search by multiple ORed classification codes' do
      expected_codes = %w[D0001 D0002]
      params = {
        'classification' => expected_codes.join(',')
      }

      bundle = CitationFilter.new(params: params, artifact_base_url: @artifact_base_url,
                                  redirect_base_url: @redirect_base_url,
                                  request_url: @request_url).citations

      assert_bundle(bundle)

      result = bundle.entry.all? do |entry|
        entry.resource.citedArtifact.classification.any? do |classification|
          classification.classifier.any? do |classifier|
            classifier.coding.any? { |coding| coding.code == expected_codes[0] || coding.code == expected_codes[1] }
          end
        end
      end

      assert result
    end

    it 'sorts results by code match count' do
      search_codes = %w[D0001 D0002]
      params = {
        'classification' => search_codes.join(',')
      }

      bundle = CitationFilter.new(params: params, artifact_base_url: @artifact_base_url,
                                  redirect_base_url: @redirect_base_url,
                                  request_url: @request_url).citations

      assert_bundle(bundle)
      assert_equal('Bladder cancer', bundle.entry[0].resource.title)
    end

    it 'sorts results by publication date, all else being equal' do
      search_codes = %w[D0002]
      params = {
        'classification' => search_codes.join(',')
      }

      bundle = CitationFilter.new(params: params, artifact_base_url: @artifact_base_url,
                                  redirect_base_url: @redirect_base_url,
                                  request_url: @request_url).citations

      assert_bundle(bundle)
      assert_equal('Diabetes', bundle.entry[0].resource.title)
    end

    it 'supports search by multiple ANDed classification codes' do
      expected_codes = %w[D0001 D0002]
      params = {
        'classification' => expected_codes
      }

      bundle = CitationFilter.new(params: params, artifact_base_url: @artifact_base_url,
                                  redirect_base_url: @redirect_base_url,
                                  request_url: @request_url).citations
      assert_bundle(bundle)

      result = expected_codes.all? do |expected_code|
        bundle.entry.all? do |entry|
          entry.resource.citedArtifact.classification.any? do |classification|
            classification.classifier.any? do |classifier|
              classifier.coding.any? { |coding| coding.code == expected_code }
            end
          end
        end
      end

      assert result
    end

    it 'supports search by artifact-current-state' do
      expected = 'active'
      params = {
        'artifact-current-state' => expected
      }

      bundle = CitationFilter.new(params: params, artifact_base_url: @artifact_base_url,
                                  redirect_base_url: @redirect_base_url,
                                  request_url: @request_url).citations

      assert_bundle(bundle)

      assert bundle.entry.all? do |entry|
        entry.resource.citedArtifact.currentState.any? do |state|
          state.coding.any? { |coding| coding.code == expected }
        end
      end
    end

    it 'supports search by multiple artifact-current-state' do
      expected = %w[active retired retracted]
      params = {
        'artifact-current-state' => expected.join(',')
      }

      bundle = CitationFilter.new(params: params, artifact_base_url: @artifact_base_url,
                                  redirect_base_url: @redirect_base_url,
                                  request_url: @request_url).citations

      assert_bundle(bundle)

      assert bundle.entry.all? do |entry|
        entry.resource.citedArtifact.currentState.any? do |state|
          state.coding.any? { |coding| expected.include?(coding.code) }
        end
      end
    end

    it 'supports search by artifact-type' do
      expected = 'Guidance'
      params = {
        'artifact-type': expected
      }

      bundle = CitationFilter.new(params: params, artifact_base_url: @artifact_base_url,
                                  redirect_base_url: @redirect_base_url,
                                  request_url: @request_url).citations

      assert_bundle(bundle)

      assert bundle.entry.all? do |entry|
        entry.resource.citedArtifact.classification.any? do |state|
          state.classifier.any? { |classifier| classifier.text == expected }
        end
      end
    end

    it 'supports search by multiple artifact-type' do
      expected = ['Guidance', 'Systematic Review']
      params = {
        'artifact-type': expected.join(',')
      }

      bundle = CitationFilter.new(params: params, artifact_base_url: @artifact_base_url,
                                  redirect_base_url: @redirect_base_url,
                                  request_url: @request_url).citations

      assert_bundle(bundle)

      assert bundle.entry.all? do |entry|
        entry.resource.citedArtifact.classification.any? do |state|
          state.classifier.any? { |classifier| classifier.text == expected }
        end
      end
    end

    it 'supports _sort parameter for search result ordering' do
      search_codes = %w[D0002]
      params = {
        'classification' => search_codes.join(','),
        '_sort' => 'article-date' # ascending date order
      }

      bundle = CitationFilter.new(params: params, artifact_base_url: @artifact_base_url,
                                  redirect_base_url: @redirect_base_url,
                                  request_url: @request_url).citations

      assert_bundle(bundle)
      assert_equal('Bladder cancer', bundle.entry[0].resource.title)

      params['_sort'] = '-article-date' # descending date order
      bundle = CitationFilter.new(params: params, artifact_base_url: @artifact_base_url,
                                  redirect_base_url: @redirect_base_url,
                                  request_url: @request_url).citations

      assert_bundle(bundle)
      assert_equal('Diabetes', bundle.entry[0].resource.title)

      params['_sort'] = 'foo' # invalid sort field
      assert_raises InvalidParameterError do
        bundle = CitationFilter.new(params: params, artifact_base_url: @artifact_base_url,
                                    redirect_base_url: @redirect_base_url,
                                    request_url: @request_url).citations
      end
    end

    it 'supports _count parameter for pagination' do
      expected = 1
      params = {
        '_count' => expected.to_s
      }

      bundle = CitationFilter.new(params: params, artifact_base_url: @artifact_base_url,
                                  redirect_base_url: @redirect_base_url,
                                  request_url: @request_url).citations

      assert_bundle(bundle, assert_total: false)
      assert_paging(bundle, expected, 1)
    end

    it 'supports _count parameter for pagination and page parameter for selected page' do
      count = 1
      page = 2
      params = {
        '_count' => count.to_s,
        'page' => page.to_s
      }

      bundle = CitationFilter.new(params: params, artifact_base_url: @artifact_base_url,
                                  redirect_base_url: @redirect_base_url,
                                  request_url: @request_url).citations

      assert_bundle(bundle, assert_total: false)
      assert_paging(bundle, count, page)
    end

    it 'supports selected last page' do
      count = 1
      page = (Artifact.count / count).ceil
      params = {
        '_count' => count.to_s,
        'page' => page.to_s
      }

      bundle = CitationFilter.new(params: params, artifact_base_url: @artifact_base_url,
                                  redirect_base_url: @redirect_base_url,
                                  request_url: @request_url).citations

      assert_bundle(bundle, assert_total: false)
      assert_paging(bundle, count, page)
    end

    it 'supports artifact-publisher parameter' do
      expected = 'CDS-connect'
      params = {
        'artifact-publisher' => expected
      }

      bundle = CitationFilter.new(params: params, artifact_base_url: @artifact_base_url,
                                  redirect_base_url: @redirect_base_url,
                                  request_url: @request_url).citations

      assert_bundle(bundle)
      assert bundle.entry.all? do |entry|
        entry.resource.citedArtifact.publicationForm.any? { |f| f.publishedIn.publisher.display.casecmp?(expected) }
      end
    end
  end

  describe 'save request' do
    before do
      @artifact_base_url = 'http://localhost/fhir/Citation'
      @request_url = 'http://example.com/fhir/Citation'
    end

    it 'logs request to database' do
      expected = 'cancer'
      params = {
        '_content' => expected
      }

      citations = CitationFilter.new(params: params,
                                     artifact_base_url: @artifact_base_url,
                                     redirect_base_url: @redirect_base_url,
                                     request_url: @request_url,
                                     client_ip: '::1',
                                     log_to_db: true)
                                .citations

      log = SearchLog.order(Sequel.desc(:id)).first

      refute log.nil?
      refute log.search_params.nil?
      refute log.search_params['_content'].nil?
      assert_equal log.search_params['_content'], expected
      refute log.count.nil?
      refute log.total.nil?
      refute log.client_ip.nil?
      refute log.start_time.nil?
      refute log.end_time.nil?
      refute log.repository_results.nil?
      refute log.repository_results['101'].nil?
      assert_equal 'USPSTF', log.repository_results['101']['alias']
      refute log.repository_results['102'].nil?
      assert_equal 'CDS Connect', log.repository_results['102']['alias']
      logged_result_count = log.repository_results.values.inject(0) { |total, repo_entry| total + repo_entry['count'] }
      assert_equal citations.entry.size, logged_result_count
    end
  end
end
