# frozen_string_literal: true

# Helper methods for CEDAR API
class ApiHelper
  def self.parse_full_text_search(term)
    tokens = term.split

    phrase = false
    result = ''
    tokens.each do |token|
      result += if phrase
                  '<->'
                else
                  ' '
                end

      case token
      when 'AND'
        result += '&'
        next
      when 'OR'
        result += '|'
        next
      when 'NOT'
        result += '!'
        next
      end

      i = start_with_quote(token)

      if i >= 0
        phrase = true

        result += token[0..i - 1] if i.positive?

        result += token[i + 1..]
        next
      end

      i = end_with_quote(token)

      if i >= 0
        phrase = false
        result += token[0..i - 1]

        result += token[i + 1..] if i < token.length - 1
      else
        result += token
      end
    end

    result.strip
  end

  def self.start_with_quote(token)
    i = 0

    i += 1 while token[i] == '('

    token[i] == '"' ? i : -1
  end

  def self.end_with_quote(token)
    i = token.length - 1

    i -= 1 while token[i] == ')'

    token[i] == '"' ? i : -1
  end
end
