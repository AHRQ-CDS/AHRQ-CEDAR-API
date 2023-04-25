# frozen_string_literal: true

require 'cgi'
require 'csv'
require 'fhir_models'
require 'json'
require 'sinatra'
require 'sinatra/namespace'
require 'sinatra/cross_origin'
require 'sinatra/required_params'

require_relative 'util/cedar_logger'
require_relative 'database/models'
require_relative 'fhir/fhir_adapter'
require_relative 'util/citation_filter'
require_relative 'util/search_parser'

configure do
  # Support cross-origin requests to allow JavaScript-based UIs hosted on different servers
  enable :cross_origin
  set :logger, CedarLogger.logger
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

get '/suggestions' do
  required_params :term
  term = params[:term]
  begin
    result_names = if term.empty?
                     []
                   else
                     MeshTreeNode.similar_to_name(term).collect { |r| r[:name] }
                   end

    content_type 'application/json'
    { suggestions: result_names, term: term }.to_json
  rescue StandardError => e
    logger.error "Suggestions error: #{e.full_message}"
    content_type 'text/plain'
    status 500
    return 'Error finding suggestions.'
  end
end

get '/redirect/:id' do
  id = params[:id]
  artifact = Artifact.first(cedar_identifier: id)
  if artifact.nil?
    logger.info "Redirect for unknown artifact (#{id})"
    halt(404)
  elsif artifact.url.nil?
    logger.info "Redirect for retracted artifact (#{id})"
    halt(404)
  end

  search_log = SearchLog[params[:search]]
  if search_log.nil?
    logger.info "Redirect for artifact (#{id}) but search log #{params[:search]} not found"
  else
    search_log.link_clicks ||= []
    search_log.link_clicks << { artifact_id: artifact.id, position: params[:result].to_i, referrer: request.referrer }
    repo_result = search_log.repository_results[artifact.repository_id.to_s]
    if repo_result.nil?
      logger.info "Redirect for artifact (#{id}) but artifact repository not in search log #{params[:search]}"
    else
      repo_result['clicked'] ||= 0
      repo_result['clicked'] += 1
    end
    search_log.save
  end

  redirect artifact.url
end

get '/csv' do
  multiple_and_parameters = CGI.parse(request.query_string).select do |k, _v|
    CitationFilter::MULTIPLE_AND_PARAMETERS.include?(k)
  end

  request_url = "#{request.scheme}://#{request.host}:#{request.port}#{request.path}"
  redirect_base_url = uri('redirect').to_s
  filter = CitationFilter.new(params: params.merge(multiple_and_parameters),
                              artifact_base_url: uri('fhir/Citation').to_s,
                              redirect_base_url: redirect_base_url,
                              request_url: request_url,
                              client_ip: request.ip,
                              client_id: request.env['HTTP_FROM'],
                              log_to_db: true)
  begin
    artifacts = filter.all_artifacts
  rescue StandardError => e
    logger.error "Search error: #{e.full_message}"
    content_type 'text/plain'
    status 500
    return 'Error executing query.'
  end

  content_type 'text/csv'
  attachment "cedar_#{Time.now.strftime('%Y%m%d-%H%M%S')}.csv"
  stream do |out|
    out << CSV.generate_line(
      %w[Repository Title Description Keywords UMLS MeSH SNOMED-CT ICD10CM RXNORM Status Published Link]
    )
    artifacts.each_with_index do |artifact, result_index|
      truncated_description = artifact.description
      if truncated_description && truncated_description.size > 300
        truncated_description = "#{truncated_description[..300]}..."
      end
      out << CSV.generate_line([artifact.repository.alias,
                                artifact.title,
                                truncated_description,
                                artifact.keywords.join('; '),
                                stringify(artifact.concepts, 'UMLS'),
                                stringify(artifact.concepts, 'MSH'),
                                stringify(artifact.concepts, 'SNOMEDCT_US'),
                                stringify(artifact.concepts, 'ICD10CM'),
                                stringify(artifact.concepts, 'RXNORM'),
                                artifact.artifact_status,
                                artifact.published_on,
                                if FHIRAdapter::ARTIFACT_URL_CLICK_LOGGING
                                  "#{redirect_base_url}/#{artifact.cedar_identifier}?result=#{result_index}"
                                else
                                  artifact.url
                                end])
    end
  end
end

def stringify(concepts, code_system)
  if code_system == 'UMLS'
    concepts.map { |concept| "#{concept.umls_cui} (#{concept.umls_description})" }.join('; ')
  else
    concept_codes = concepts.map do |concept|
      codes = concept.codes.select do |code|
        code['system'] == code_system
      end
      codes.map do |code|
        "#{code['code']} (#{code['description']})"
      end.join('; ')
    end
    concept_codes.select { |str| str&.size&.positive? }.join('; ')
  end
end

not_found do
  logger.info "Request for unknown URL (#{request.url})"
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
    cs.to_json
  end

  get '/SearchParameter/?:id?' do
    read_resource_from_file('SearchParameter', params)
  end

  get '/OperationDefinition/?:id?' do
    read_resource_from_file('OperationDefinition', params)
  end

  get '/StructureDefinition/?:id?' do
    read_resource_from_file('StructureDefinition', params)
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
    if repository.nil?
      logger.info "Request for unknown repository id (#{id})"
      halt(404)
    end

    citation = FHIRAdapter.create_organization(repository)
    citation.to_json
  end

  get '/Citation/$get-artifact-types' do
    output = Artifact.exclude(artifact_type: '').order(:artifact_type).distinct(:artifact_type).select(:artifact_type)
    output = FHIRAdapter.create_artifact_types_output(output)
    output.to_json
  end

  get '/Citation/:id' do
    id = params[:id]

    artifact = Artifact.first(cedar_identifier: id)
    if artifact.nil?
      logger.info "Request for unknown artifact id (#{id})"
      halt(404)
    end

    citation = FHIRAdapter.create_citation(artifact, uri('fhir/Citation'), uri('redirect'),
                                           artifact.public_version_history.count + 1)
    citation.to_json
  end

  # Return a particular historical version of an artifact. If an artifact has N versions, we can return one of
  # the N - 1 historical versions retrieved via Artifact#public_version_history or we can return the current version
  get '/Citation/:id/_history/:version_id' do
    id = params[:id]
    version_id = params[:version_id].to_i
    if version_id < 1
      logger.info "Request for invalid artifact (#{id}) version id (#{version_id})"
      halt(404)
    end

    base_artifact = Artifact.first(cedar_identifier: id)
    if base_artifact.nil?
      logger.info "Request for unknown artifact id (#{id})"
      halt(404)
    end

    version_history = base_artifact.public_version_history
    if version_id > version_history.count + 1
      logger.info "Request for invalid artifact (#{id}) version id (#{version_id})"
      halt(404)
    end

    citation = nil

    if version_id <= version_history.count
      versioned_artifact = version_history[version_id - 1].build_artifact
      citation = FHIRAdapter.create_citation(versioned_artifact, uri('fhir/Citation'), uri('redirect'),
                                             version_id, skip_concept: true)
    else
      citation = FHIRAdapter.create_citation(base_artifact, uri('fhir/Citation'), uri('redirect'), version_id)
    end

    citation.to_json
  end

  get '/Citation' do
    # artifact-current-state is required
    unless params&.any? { |key, _value| key == 'artifact-current-state' }
      logger.info 'Search request missing artifact-current-state'
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

    multiple_and_parameters = CGI.parse(request.query_string).select do |k, _v|
      CitationFilter::MULTIPLE_AND_PARAMETERS.include?(k)
    end

    request_url = "#{request.scheme}://#{request.host}:#{request.port}#{request.path}"
    filter = CitationFilter.new(params: params.merge(multiple_and_parameters),
                                artifact_base_url: uri('fhir/Citation').to_s,
                                redirect_base_url: uri('redirect').to_s,
                                request_url: request_url,
                                client_ip: request.ip,
                                client_id: request.env['HTTP_FROM'],
                                log_to_db: true)
    begin
      bundle = filter.citations
      bundle.to_json
    rescue FhirError => e
      logger.error "Error creating FHIR Bundle: #{e.full_message}"
      e.to_operation_outcome_json
    rescue StandardError => e
      logger.error "Search error: #{e.full_message}"
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

      oo.to_json
    end
  end

  get '/CodeSystem/$get-mesh-children' do
    if params[:code].nil?
      tree_nodes = MeshTreeNode.where(parent_id: nil).order(:name)
    else
      parent_node = MeshTreeNode.where(tree_number: params[:code]).first
      return FHIR::Parameters.new.to_json if parent_node.nil?

      tree_nodes = parent_node.children
    end

    output = FHIRAdapter.create_mesh_children_output(tree_nodes)
    output.to_json
  end

  def read_resource_from_file(path, params)
    # We do not return files based on file names built from user-supplied parameters to prevent users from
    # reading arbitrary files; instead, we 1) get a listing of valid files 2) see if there's a file that
    # matches the requested file, and 3) return the matching file if present
    id = params[:id] || params[:url].split('/').last
    valid_files = Dir['resources/*.json']
    matching_file = valid_files.detect { |f| f == "resources/#{path}-#{id}.json" }
    if matching_file && File.exist?(matching_file)
      FHIR.from_contents(File.read(matching_file)).to_json
    else
      logger.info "Request for unknown resource: #{id}"
      halt(404)
    end
  end
end
