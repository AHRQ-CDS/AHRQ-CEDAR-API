# frozen_string_literal: true

require 'fhir_models'
require 'json'
require 'pry'
require 'sinatra'
require 'sinatra/namespace'
require 'sinatra/cross_origin'

require_relative 'database/models'
require_relative 'fhir/fhir_adapter'
require_relative 'util/citation_filter'
require_relative 'util/search_parser'

configure do
  # Support cross-origin requests to allow JavaScript-based UIs hosted on different servers
  enable :cross_origin
end

get '/' do
  "Artifact count: #{Artifact.count}"
end

get '/demo' do
  content_type 'text/html'
  <<~DEMO_FORM
    <form action="fhir/Citation" method="get">
      <label for="_content">Search Text:</label>
      <input type="text" id="_content" name="_content">
      <input type="hidden" id="artifact-current-state" name="artifact-current-state" value="active">
      <button type="submit">Search</button>
    </form>
    <form action="fhir/Citation" method="get">
      <label for="Last Updated">Last Updated:</label>
      <input type="text" id="_lastUpdated" name="_lastUpdated">
      <input type="hidden" id="artifact-current-state" name="artifact-current-state" value="active">
      <button type="submit">Search</button>
    </form>
    <form action="fhir/Citation" method="get">
      <label for="keyword">Search Keywords:</label>
      <input type="text" id="classification:text" name="classification:text">
      <input type="hidden" id="artifact-current-state" name="artifact-current-state" value="active">
      <button type="submit">Search</button>
    </form>
    <form action="fhir/Citation" method="get">
      <label for="keyword">Search Concepts:</label>
      <input type="text" id="classification" name="classification">
      <input type="hidden" id="artifact-current-state" name="artifact-current-state" value="active">
      <button type="submit">Search</button>
    </form>
    <form action="fhir/Citation" method="get">
      <label for="title">Search Title:</label>
      <input type="text" id="title" name="title:contains">
      <input type="hidden" id="artifact-current-state" name="artifact-current-state" value="active">
      <button type="submit">Search</button>
    </form>
  DEMO_FORM
end

not_found do
  'Not found'
end

namespace '/fhir' do
  before do
    content_type 'application/fhir+json; charset=utf-8'
    response.headers['Access-Control-Allow-Origin'] = '*'
  end

  get '/metadata' do
    json = File.read('resources/capabilitystatement.json')
    cs = FHIR.from_contents(json)
    return cs.to_json
  end

  get '/SearchParameter/?:id?' do
    read_resource_from_file(params, 'SearchParameter')
  end

  get '/OperationDefinition/?:id?' do
    read_resource_from_file(params, 'OperationDefinition')
  end

  get '/StructureDefinition/?:id?' do
    read_resource_from_file(params, 'StructureDefinition')
  end

  get '/Organization' do
    bundle = FHIRAdapter.create_organization_bundle(Repository.all)

    uri = Addressable::URI.parse("#{request.scheme}://#{request.host}:#{request.port}#{request.path}")

    bundle.link << FHIR::Bundle::Link.new(
      {
        relation: 'self',
        url: uri.normalize.to_str
      }
    )

    bundle.to_json
  end

  get '/Organization/:id' do
    id = params[:id]

    repository = Repository.first(fhir_id: id)
    halt(404) if repository.nil?

    citation = FHIRAdapter.create_organization(repository)
    citation.to_json
  end

  get '/Citation/:id' do
    id = params[:id]

    artifact = Artifact.first(cedar_identifier: id)
    halt(404) if artifact.nil?

    citation = FHIRAdapter.create_citation(artifact, uri('fhir/Citation'))
    citation.to_json
  end

  get '/Citation' do
    # artifact-current-state is required
    unless params&.any? { |key, _value| key == 'artifact-current-state' }
      oo = FHIR::OperationOutcome.new(
        issue: [
          {
            severity: 'error',
            code: 'required',
            details: {
              text: 'Required search parameter artifact-current-state is missing'
            }
          }
        ]
      )

      return oo.to_json
    end

    request_url = "#{request.scheme}://#{request.host}:#{request.port}#{request.path}"
    filter = CitationFilter.new(params: params,
                                base_url: uri('fhir/Citation').to_s,
                                request_url: request_url,
                                client_ip: request.ip,
                                log_to_db: true)
    begin
      bundle = filter.citations
      bundle.to_json
    rescue FhirError => e
      e.to_operation_outcome_json
    rescue StandardError => e
      oo = FHIR::OperationOutcome.new(
        issue: [
          {
            severity: 'error',
            code: 'exception',
            details: {
              text: e.message
            }
          }
        ]
      )

      return oo.to_json
    end
  end

  get '/CodeSystem/$get-mesh-children' do
    if params[:code].nil?
      tree_nodes = MeshTreeNode.where(parent_id: nil)
    else
      parent_node = MeshTreeNode.where(tree_number: params[:code]).first
      return FHIR::Parameters.new.to_json if parent_node.nil?

      tree_nodes = parent_node.children
    end

    output = FHIRAdapter.create_mesh_children_output(tree_nodes)
    output.to_json
  end

  def read_resource_from_file(params, path)
    file_prefix = "resources/#{path}-"
    if !params[:id].nil?
      filename = "#{file_prefix}#{params[:id]}.json"
    elsif !params[:url].nil?
      filename = "#{params['url'].gsub(%r{.*#{path}/}, file_prefix)}.json"
    else
      halt(400)
    end

    if File.exist? filename
      FHIR.from_contents(File.read(filename)).to_json
    else
      halt(404)
    end
  end
end
