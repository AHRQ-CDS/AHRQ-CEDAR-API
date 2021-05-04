# frozen_string_literal: true

require 'addressable'

# Helper methods for CEDAR API
class ApiHelper
  def self.build_next_page_url(request, page_no = 0, page_size = 0)
    uri = Addressable::URI.parse("#{request.scheme}://#{request.host}:#{request.port}#{request.path}")
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
