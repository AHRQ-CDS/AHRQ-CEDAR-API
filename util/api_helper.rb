# frozen_string_literal: true

require 'addressable'

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

  def self.build_next_page_url(request, page_no = 0, page_size = 0)
    uri = Addressable::URI.parse("#{request.scheme}://#{request.host}:#{request.port}/#{request.path}")
    params = {}

    request.params.each do |key, value|
      next if %w[_count page].include?(key)

      params[key.to_sym] = value
    end

    if page_size.positive?
      params[:_count] = page_size
      params[:page] = page_no if page_no.positive?
    end

    uri.query_values = params
    uri.normalize.to_str
  end
end
