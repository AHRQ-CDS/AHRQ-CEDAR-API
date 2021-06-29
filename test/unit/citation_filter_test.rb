# frozen_string_literal: true

require 'warning'
require_relative '../test_helper'
require_relative '../../database/models'

describe CitationFilter do
  include Rack::Test::Methods
  include CedarApi::TestHelper

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

  describe 'find citiation' do
    before do
      @artifact_base_url = 'http://localhost/fhir/Citation'
      @request_url = 'http://example.com/fhir/Citation'
    end

    it 'supports search by _content' do
      expected = 'cancer'
      params = {
        '_content' => expected
      }

      bundle = CitationFilter.new(params: params, base_url: @artifact_base_url, request_url: @request_url).citations

      assert_bundle(bundle)

      assert bundle.entry.all? do |entry|
        entry.resource.title.downcase.include?(expected) ||
          entry.resource.description.downcase.include?(expected)
      end
    end

    it 'supports search by title' do
      expected = 'diabetes'
      params = {
        'title' => expected
      }

      bundle = CitationFilter.new(params: params, base_url: @artifact_base_url, request_url: @request_url).citations

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

      bundle = CitationFilter.new(params: params, base_url: @artifact_base_url, request_url: @request_url).citations

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

      bundle = CitationFilter.new(params: params, base_url: @artifact_base_url, request_url: @request_url).citations

      assert_bundle(bundle)

      assert bundle.entry.all? do |entry|
        entry.resource.title.downcase.include?(expected)
      end
    end

    it 'supports search by classification text' do
      expected = 'diabetes'
      params = {
        'classification:text' => expected
      }

      bundle = CitationFilter.new(params: params, base_url: @artifact_base_url, request_url: @request_url).citations

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

      bundle = CitationFilter.new(params: params, base_url: @artifact_base_url, request_url: @request_url).citations

      assert_bundle(bundle)

      assert bundle.entry.all? do |entry|
        entry.resource.citedArtifact.classification.any? do |classification|
          classification.classifier.any? { |classifier| expected.include?(classifier.text.downcase) }
        end
      end
    end

    it 'supports search by classification system and code' do
      expected_system = 'https://www.nlm.nih.gov/mesh/'
      expected_code = 'D0001'
      params = {
        'classification' => "#{expected_system}|#{expected_code}"
      }

      bundle = CitationFilter.new(params: params, base_url: @artifact_base_url, request_url: @request_url).citations

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

      bundle = CitationFilter.new(params: params, base_url: @artifact_base_url, request_url: @request_url).citations

      assert_bundle(bundle)

      assert bundle.entry.all? do |entry|
        entry.resource.citedArtifact.classification.any? do |classification|
          classification.classifier.any? do |classifier|
            classifier.coding.any? { |coding| coding.code == expected_code }
          end
        end
      end
    end

    it 'supports search by artifact-current-state' do
      expected = 'active'
      params = {
        'artifact-current-state' => expected
      }

      bundle = CitationFilter.new(params: params, base_url: @artifact_base_url, request_url: @request_url).citations

      assert_bundle(bundle)

      assert bundle.entry.all? do |entry|
        entry.resource.citedArtifact.currentState.any? do |state|
          state.coding.any? { |coding| coding.code == expected }
        end
      end
    end

    it 'supports search by multiple artifact-current-state' do
      expected = %w[active retired]
      params = {
        'artifact-current-state' => expected.join(',')
      }

      bundle = CitationFilter.new(params: params, base_url: @artifact_base_url, request_url: @request_url).citations

      assert_bundle(bundle)

      assert bundle.entry.all? do |entry|
        entry.resource.citedArtifact.currentState.any? do |state|
          state.coding.any? { |coding| expected.include?(coding.code) }
        end
      end
    end

    it 'supports _count parameter for pagination' do
      expected = 1
      params = {
        '_count' => expected.to_s
      }

      bundle = CitationFilter.new(params: params, base_url: @artifact_base_url, request_url: @request_url).citations

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

      bundle = CitationFilter.new(params: params, base_url: @artifact_base_url, request_url: @request_url).citations

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

      bundle = CitationFilter.new(params: params, base_url: @artifact_base_url, request_url: @request_url).citations

      assert_bundle(bundle, assert_total: false)
      assert_paging(bundle, count, page)
    end

    it 'supports artifact-publisher parameter' do
      expected = 'CDS-connect'
      params = {
        'artifact-publisher' => expected
      }

      bundle = CitationFilter.new(params: params, base_url: @artifact_base_url, request_url: @request_url).citations

      assert_bundle(bundle)
      assert bundle.entry.all? do |entry|
        entry.resource.citedArtifact.publicationForm.any? { |f| f.publishedIn.publisher.display.casecmp?(expected) }
      end
    end
  end

  describe 'save request' do
    before do
      Warning.ignore(/instance variable @\w+ not initialized/)
      @artifact_base_url = 'http://localhost/fhir/Citation'
      @request_url = 'http://example.com/fhir/Citation'
    end

    it 'logs rquest to database' do
      expected = 'cancer'
      params = {
        '_content' => expected
      }

      CitationFilter.new(params: params,
                         base_url: @artifact_base_url,
                         request_url: @request_url,
                         client_ip: '::1',
                         log_to_db: true)
                    .citations

      log = SearchLog.order(Sequel.desc(:id)).first

      refute log.nil?
      refute log[:search_params].nil?
      refute log[:search_type].nil?
      refute log[:sql].nil?
      refute log[:count].nil?
      refute log[:client_ip].nil?
      refute log[:start_time].nil?
      refute log[:end_time].nil?
    end
  end
end
