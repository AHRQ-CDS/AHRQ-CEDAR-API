# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../database/models'

describe 'cedar_api' do
  include Rack::Test::Methods
  include CedarApi::TestHelper

  def assert_bundle(assert_total: true)
    assert last_response.ok?
    bundle = FHIR.from_contents(last_response.body)

    refute_nil bundle
    assert bundle.is_a?(FHIR::Bundle)
    assert_equal 'searchset', bundle.type
    assert_equal bundle.total, bundle.entry.size if assert_total
    assert bundle.entry.size.positive?

    bundle
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

  describe 'root' do
    it 'returns count of artifacts' do
      get '/'
      assert last_response.ok?
      assert_equal "Artifact count: #{Artifact.count}", last_response.body
    end

    it 'returns not found when endpoint does not exist' do
      get '/foobar'
      assert last_response.not_found?
    end
  end

  describe '/fhir endpoint' do
    it 'returns CapabilityStatement from /metadata endpoint' do
      get '/fhir/metadata'

      assert last_response.ok?
      resource = FHIR.from_contents(last_response.body)
      refute_nil resource
      assert resource.is_a?(FHIR::CapabilityStatement)
    end

    it 'returns not found for not supported resource type' do
      get '/fhir/EvidenceReport/1000'
      assert last_response.not_found?
    end
  end

  describe '/fhir/Citation endpoint' do
    it 'supports read with id' do
      get '/fhir/Citation/abc-1'

      assert last_response.ok?
      resource = FHIR.from_contents(last_response.body)

      refute_nil resource
      assert resource.is_a?(FHIR::Citation)
      assert_equal 'abc-1', resource.id
      assert_equal 'active', resource.status
    end

    it 'returns not found when read with invalid id' do
      get '/fhir/Citation/1000'
      assert last_response.not_found?
    end

    it 'supports search by _content' do
      get '/fhir/Citation?_content=cancer&artifact-current-state=active'
      bundle = assert_bundle

      assert bundle.entry.all? do |entry|
        entry.resource.title.downcase.include?('cancer') ||
          entry.resource.description.downcase.include?('cancer')
      end
    end

    it 'supports search by title' do
      get '/fhir/Citation?title=diabetes&artifact-current-state=active'
      bundle = assert_bundle
      assert bundle.entry.all? do |entry|
        entry.resource.title.downcase.start_with?('diabetes')
      end
    end

    it 'supports search by title with multiple OR' do
      get '/fhir/Citation?title=cancer,diabetes&artifact-current-state=active'
      bundle = assert_bundle
      assert bundle.entry.all? do |entry|
        entry.resource.title.downcase.start_with?('diabetes') ||
          entry.resource.title.downcase.start_with?('cancer')
      end
    end

    it 'supports search by title with :contains modifier' do
      get '/fhir/Citation?title:contains=diabetes&artifact-current-state=active'
      bundle = assert_bundle
      assert bundle.entry.all? do |entry|
        entry.resource.title.downcase.include?('diabetes')
      end
    end

    it 'supports search by keyword' do
      get '/fhir/Citation?keyword=diabetes&artifact-current-state=active'
      bundle = assert_bundle
      assert bundle.entry.all? do |entry|
        entry.resource.keywordList.any? do |keyword_list|
          keyword_list.keyword.any { |keyword| keyword.value.downcase == 'diabetes' }
        end
      end
    end

    it 'supports search by keyword with multiple OR' do
      get '/fhir/Citation?keyword=diabetes,Adult&artifact-current-state=active'
      bundle = assert_bundle
      assert bundle.entry.all? do |entry|
        entry.resource.keywordList.any? do |keyword_list|
          keyword_list.keyword.any do |keyword|
            keyword.value.downcase == 'diabetes' || keyword.value.downcase == 'adult'
          end
        end
      end
    end

    it 'requires artifact-current-state search parameter' do
      get 'fhir/Citation?_content=cancer'

      assert last_response.ok?
      resource = FHIR.from_contents(last_response.body)

      refute_nil resource
      assert resource.is_a?(FHIR::OperationOutcome)
      assert resource.issue.size.positive?
      assert resource.issue.any? do |issue|
        issue.severity == 'error' && issue.code == 'required'
      end
    end

    it 'supports search by artifact-current-state' do
      get '/fhir/Citation?artifact-current-state=active'
      bundle = assert_bundle
      assert bundle.entry.all? do |entry|
        entry.resource.citedArtifact.currentState.any? do |state|
          state.coding.any? { |coding| coding.code == 'active' }
        end
      end
    end

    it 'supports search by multiple artifact-current-state' do
      get '/fhir/Citation?artifact-current-state=active,retired'
      bundle = assert_bundle
      assert bundle.entry.all? do |entry|
        entry.resource.citedArtifact.currentState.any? do |state|
          state.coding.any? { |coding| %w[active retired].include?(coding.code) }
        end
      end
    end

    it 'supports _count parameter for pagination' do
      count = 1
      get "/fhir/Citation?artifact-current-state=active,retired&_count=#{count}"
      bundle = assert_bundle(assert_total: false)

      assert_paging(bundle, count, 1)
    end

    it 'supports _count parameter for pagination and page parameter for selected page' do
      count = 1
      page = 2
      get "/fhir/Citation?artifact-current-state=active,retired&_count=#{count}&page=#{page}"
      bundle = assert_bundle(assert_total: false)

      assert_paging(bundle, count, page)
    end

    it 'supports selected last page' do
      count = 1
      page = (Artifact.count / count).ceil
      get "/fhir/Citation?artifact-current-state=active,retired&_count=#{count}&page=#{page}"
      bundle = assert_bundle(assert_total: false)

      assert_paging(bundle, count, page)
    end

    it 'supports artifact-publisher parameter' do
      publisher = 'CDS-connect'
      get "/fhir/Citation?artifact-current-state=active&artifact-publisher=#{publisher}"
      bundle = assert_bundle

      assert bundle.entry.all? do |entry|
        entry.resource.citedArtifact.publicationForm.any? { |f| f.publishedIn.publisher.display.casecmp?(publisher) }
      end
    end
  end

  describe '/fhir/Organization endpoint' do
    it 'supports read by id' do
      repo_id = 'uspstf'
      get "/fhir/Organization/#{repo_id}"

      assert last_response.ok?
      resource = FHIR.from_contents(last_response.body)
      refute_nil resource
      assert resource.is_a?(FHIR::Organization)
      assert_equal(repo_id, resource.id)
    end

    it 'supports read all repositories' do
      get '/fhir/Organization'

      assert last_response.ok?
      resource = FHIR.from_contents(last_response.body)
      refute_nil resource
      assert resource.is_a?(FHIR::Bundle)

      assert_equal(resource.total, Repository.count)
      assert_equal(resource.total, resource.entry.length)
    end
  end
end
