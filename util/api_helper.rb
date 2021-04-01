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

      if token[0] == '"'
        phrase = true
        result += token[1..]
      elsif token[token.length - 1] == '"'
        phrase = false
        result += token[0..token.length - 2]
      elsif token == 'AND'
        result += '&'
      elsif token == 'OR'
        result += '|'
      elsif token == 'NOT'
        result += '!'
      else
        result += token
      end
    end

    result.strip
  end
end
