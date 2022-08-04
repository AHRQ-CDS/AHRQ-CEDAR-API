# frozen_string_literal: true

# Class to wrap a singleton Hash instance that contains a list of free text search "stop words"
# see: https://www.postgresql.org/docs/current/textsearch-dictionaries.html#TEXTSEARCH-STOPWORDS
class StopWords
  extend SingleForwardable

  def_delegators :list, :include?

  @_list = nil
  class << self
    def list
      return @_list unless @_list.nil?

      list = {}
      File.readlines(File.join('config', 'stopwords.txt')).each do |line|
        next if line.start_with?('#')

        list[line.strip] = true
      end
      @_list = list
    end
  end
end
