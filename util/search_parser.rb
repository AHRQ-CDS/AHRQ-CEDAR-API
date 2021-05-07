# frozen_string_literal: true

# Parser that converts FHIR search strings into the format expected by PostgreSQL full text search
class SearchParser
  def initialize(search_string)
    @search_string = search_string
    @offset = 0
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

  # Add any configured synonyms
  def add_synonyms(term)
    synonyms_op = Sequel.pg_jsonb_op(:synonyms)
    concept = Concept.where(synonyms_op.contains([term])).first
    return term if concept.nil?

    synonyms = concept.synonyms.map do |synonym|
      tokens = synonym.split(/[, ]+/)
      tokens.length > 1 ? tokens.join('<->') : synonym
    end
    "(#{synonyms.join('|')})"
  end

  # Parse any search term, matching \w
  def parse_term(synonym_support: false)
    term = parse_regexp(/^(\w+)/)
    term = add_synonyms(term) if synonym_support
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
    OPERATORS[operator]
  end

  # Parse a parenthetical expression, returned as an array of expressions
  def parse_parenthetical
    if parse_regexp(/^(\()/)
      parenthetical = parse_expression
      parse_regexp(/^(\))/)
    end
    parenthetical
  end

  # Parse a quoted expression, returns with all contents of the string seperated with <->
  def parse_quoted
    if parse_regexp(/^(")/)
      terms = []
      while (term = parse_term)
        terms << term
      end
      parse_regexp(/^(")/)
      terms.join('<->')
    end
  end

  # Parse a series of any of the supported concepts, returned as a set of nested arrays representing parentheticals
  def parse_expression
    tokens = []
    while (token = parse_parenthetical || parse_quoted || parse_operator || parse_term(synonym_support: true))
      tokens << token
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
    # Instantiate a parser, parse the search string, and return the results with parentheticals converted
    array_to_string[new(search_string).parse_expression]
  end
end
