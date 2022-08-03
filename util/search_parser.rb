# frozen_string_literal: true

require_relative 'stop_words'

# Parser that converts FHIR search strings into the format expected by PostgreSQL full text search
class SearchParser
  attr_reader :simple_query, :simple_query_terms

  def initialize(search_string)
    @search_string = search_string
    @offset = 0
    @simple_query = true
    @simple_query_terms = []
  end

  # Return the not-yet-processed characters in the search string
  def remaining
    @search_string[@offset, @search_string.length - @offset]
  end

  # Handle parsing any arbitrary regexp; must have key content in an () expression
  def parse_regexp(regexp)
    # First consume any leading whitespace
    if (match = remaining.match(/^(\s+)/))
      @offset += match[1].length
    end
    # Consume and return content matching the regexp
    if remaining && (match = remaining.match(regexp))
      @offset += match[1].length
      match[1]
    end
  end

  # Returns a Concept for which the supplied term is a synonym or nil if none found
  def get_concepts(term, normalized_term)
    synonyms_op = Sequel.pg_jsonb_op(:synonyms_psql)
    # Concept.where(...).empty? is very slow (20X) compared to Concept.where(...).all.empty?
    search_terms = [stem(term), stem(normalized_term)].uniq.reject(&:blank?)
    return [] if search_terms.empty?

    Concept.where(synonyms_op.contain_any([stem(term), stem(normalized_term)].uniq)).all
  end

  def stem(term)
    DB['select to_tsquery(?) as query', term].first[:query].gsub('&', '<->')
    # the final gsub in the above is to account for the differences in handling hyphens in
    # phraseto_tsquery (used in the cedar_admin concepts importer, 'foo-bar' ->  "'foo-bar' <-> 'foo' <-> 'bar'")
    # and to_tsquery (used here since the parser inserts <-> between words, 'foo-bar' -> "'foo-bar' & 'foo' & 'bar'")
    # Here we are only concerned with finding matching synonyms so the gsub takes care of that.
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

    term_no_hyphens = term.gsub(/(\w)-(\w)/, '\1\2') # ignores <-> word separators
    concepts = get_concepts(term, term_no_hyphens)
    if concepts.nil? || concepts.empty?
      [term, term_no_hyphens].uniq
    else
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

  # Return the resulting search term in the format expected by PostgreSQL
  def self.parse(search_string)
    # Helper to recursively convert inner parenthetical expressions to strings surrounded by '(' and ')'
    array_to_string = lambda do |array|
      array.map { |e| e.is_a?(Array) ? "(#{array_to_string[e]})" : e }.join
    end

    # Instantiate a parser, parse the search string
    parser = new(search_string)
    tokens = parser.parse_expression

    # For simple searches (just a list of words separated by AND) add in an OR for synonyms of
    # the complete phrase (if there are any)
    if parser.simple_query && parser.simple_query_terms.size > 1
      has_hyphens = parser.simple_query_terms.any? { |term| term.include?('-') }
      simple_synonyms = parser.synonym_list(parser.simple_query_terms.join('<->'))
      if simple_synonyms.size > (has_hyphens ? 2 : 1)
        tokens = [tokens, OPERATORS['OR'], parser.synonyms_str(simple_synonyms)]
      end
    end

    # return the results with parentheticals converted
    array_to_string[tokens]
  end
end
