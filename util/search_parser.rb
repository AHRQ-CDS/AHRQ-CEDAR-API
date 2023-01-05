# frozen_string_literal: true

require_relative 'stop_words'
require_relative 'concept_helper'

# Parser that converts FHIR search strings into the format expected by PostgreSQL full text search
class SearchParser
  attr_reader :all_query_terms_that_match_concepts, :tokens

  def initialize(search_string)
    @search_string = search_string
    @offset = 0
    @simple_query = true
    @simple_query_terms = []
    @all_query_terms_that_match_concepts = []
    @tokens = tokenize
  end

  # Return the not-yet-processed characters in the search string
  def remaining
    @search_string[@offset, @search_string.length - @offset]
  end

  # Handle parsing any arbitrary regexp; must have key content in an () expression
  def parse_regexp(regexp)
    # First consume any leading whitespace and punctuation (,:;.)
    if (match = remaining.match(/^([,:;.\s]+)/))
      @offset += match[1].length
    end
    # Consume and return content matching the regexp
    if remaining && (match = remaining.match(regexp))
      @offset += match[1].length
      match[1]
    end
  end

  # Returns the supplied term if no synonyms are found or a bracketed set of synonyms
  # if any are found
  def synonyms(term)
    return nil if term.nil?

    synonyms_str(synonym_list(term))
  end

  def synonym_list(term)
    term = term.downcase
    return [term] if StopWords.include? term

    concepts = []
    # the following gsubs ignore <-> word separators that are already present
    terms = [term, term.gsub(/(\w)-(\w)/, '\1\2'), term.gsub(/(\w)-(\w)/, '\1<->\2')].uniq
    terms.each do |t|
      matching_concepts = ConceptHelper.concepts_matching(t)
      if !matching_concepts.nil? && !matching_concepts.empty?
        @all_query_terms_that_match_concepts << t
        concepts << matching_concepts
      end
    end

    if concepts.empty?
      terms
    else
      concepts = concepts.flatten.uniq(&:id)
      concepts.map(&:synonyms_psql).flatten.map { |s| s.gsub(/<->[&|!]<->/, '<->') }.uniq
    end
  end

  def synonyms_str(list)
    list.length > 1 ? "(#{list.join('|')})" : list[0]
  end

  # Parse any search term, matching alphanumerics plus a few additional characters: -, +, * and '
  def parse_term
    term = parse_regexp(/^(['\-+*\w]+)/)
    @simple_query_terms << term unless term.nil?
    term
  end

  # Parse any search term, matching alphanumerics plus a few additional characters: -, +, *, (, ) and '
  def parse_term_with_brackets
    term = parse_regexp(/^(['\-+*()\w]+)/)
    @simple_query = false unless term.nil?
    term
  end

  # The operators supported by the API and the conversion to PostgreSQL full text search
  OPERATORS = {
    'AND' => '&',
    'OR' => '|',
    'NOT' => '!'
  }.freeze

  # Parse any of the supported operators; we make sure that there's no text after the operator
  # so that we don't interpret e.g. ORGAN incorrectly
  def parse_operator
    operator = parse_regexp(/^(#{OPERATORS.keys.join('|')})(\s|\(|"|$)/)
    term = OPERATORS[operator]
    @simple_query = false unless term.nil?
    term
  end

  # Parse a parenthetical expression, returned as an array of expressions
  def parse_parenthetical
    if parse_regexp(/^(\()/)
      parenthetical = parse_expression
      parse_regexp(/^(\))/)
    end
    @simple_query = false unless parenthetical.nil?
    parenthetical
  end

  # Parse a quoted expression, returns with all contents of the string separated with <->
  def parse_quoted
    if parse_regexp(/^(")/)
      terms = []
      while (term = parse_term_with_brackets)
        terms << term
      end
      parse_regexp(/^(")/)
      @simple_query = false unless terms.empty?
      terms.join('<->')
    end
  end

  # Parse a series of any of the supported concepts, returned as a set of nested
  # arrays representing parentheticals
  def parse_expression
    tokens = []
    while (token = parse_parenthetical || synonyms(parse_quoted) || parse_operator || synonyms(parse_term))
      tokens << token unless token.empty?
    end
    # Add in the implicit & between any two tokens that don't have an operator between them
    processed_tokens = []
    tokens.length.times do |i|
      processed_tokens << tokens[i]
      # Special case, we do want to add an & between any non-operator and the ! operator if needed
      if !OPERATORS.values.include?(tokens[i]) && tokens[i + 1] && !(OPERATORS.values - ['!']).include?(tokens[i + 1])
        processed_tokens << '&'
      end
    end
    processed_tokens
  end

  def tokenize
    tokens = parse_expression

    # For simple searches (just a list of words separated by AND) add in an OR for synonyms of
    # the complete phrase (if there are any)
    if @simple_query && @simple_query_terms.size > 1
      has_hyphens = @simple_query_terms.any? { |term| term.include?('-') }
      simple_synonyms = synonym_list(@simple_query_terms.join('<->'))
      tokens = [tokens, OPERATORS['OR'], synonyms_str(simple_synonyms)] if simple_synonyms.size > (has_hyphens ? 2 : 1)
    end
    tokens
  end

  # Return the resulting search term in the format expected by PostgreSQL
  def to_postgres_query
    stringify_search(@tokens)
  end

  # Helper to recursively convert inner parenthetical expressions to strings surrounded by '(' and ')'
  def stringify_search(tokenized_expr)
    tokenized_expr.map { |e| e.is_a?(Array) ? "(#{stringify_search(e)})" : e }.join
  end

  # Class method helper
  def self.to_postgres_query(search_string)
    # Instantiate a parser, parse the search string
    parser = new(search_string)
    parser.to_postgres_query
  end
end
