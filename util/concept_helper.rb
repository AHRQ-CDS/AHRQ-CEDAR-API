# frozen_string_literal: true

require_relative '../database/models'

# Helper methods for working with concepts
class ConceptHelper
  # Returns a list of concepts for which the supplied term is a synonym or [] if none found
  def self.concepts_matching(*terms)
    synonyms_op = Sequel.pg_jsonb_op(:synonyms_psql)
    # Concept.where(...).empty? is very slow (20X) compared to Concept.where(...).all.empty?
    search_terms = terms.map { |term| stem(term) }.uniq.reject(&:blank?)
    return [] if search_terms.empty?

    Concept.where(synonyms_op.contain_any(search_terms)).all
  end

  def self.concepts_with_mesh_code_matching(*terms)
    concepts_matching(*terms).select do |concept|
      concept.codes.any? { |code| %w[MSH MSHSPA].include? code['system'] }
    end
  end

  def self.mesh_codes_matching(*terms)
    concepts_with_mesh_code_matching(*terms).map do |concept|
      concept.codes.select { |code| %w[MSH MSHSPA].include? code['system'] }.map { |code| code['code'] }
    end.flatten.uniq
  end

  # MeSH concepts can appear in multiple trees so this method can return multiple nodes
  # that have the same code but different tree_number values
  def self.mesh_nodes_matching(*terms)
    MeshTreeNode.where(code: mesh_codes_matching(*terms)).all
  end

  def self.parents_of_mesh_nodes_matching(*terms)
    mesh_nodes_matching(*terms).map(&:parent).uniq(&:id)
  end

  def self.children_of_mesh_nodes_matching(*terms)
    mesh_nodes_matching(*terms).map(&:children).flatten.uniq(&:id)
  end

  def self.concepts_with_code(system, code)
    synonyms_op = Sequel.pg_jsonb_op(:codes)
    if system.nil?
      Concept.where(synonyms_op.contains([{ code: code }])).or(umls_cui: code)
    elsif system == 'MTH'
      Concept.where(umls_cui: code)
    elsif system == 'SNOMEDCT_US' # search both English and Spanish edition
      Concept.where(synonyms_op.contains([{ system: system, code: code }, { system: 'SCTSPA', code: code }]))
    else
      Concept.where(synonyms_op.contains([{ system: system, code: code }]))
    end
  end

  def self.stem(term)
    DB['select to_tsquery(?) as query', term].first[:query].gsub('&', '<->')
    # the final gsub in the above is to account for the differences in handling hyphens in
    # phraseto_tsquery (used in the cedar_admin concepts importer, 'foo-bar' ->  "'foo-bar' <-> 'foo' <-> 'bar'")
    # and to_tsquery (used here since the parser inserts <-> between words, 'foo-bar' -> "'foo-bar' & 'foo' & 'bar'")
    # Here we are only concerned with finding matching synonyms so the gsub takes care of that.
  end
end
