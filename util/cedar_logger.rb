# frozen_string_literal: true

# Class to wrap a Logger instance for use within both Sinatra app and other classes
class CedarLogger
  extend SingleForwardable

  def_delegators :logger, :info, :error, :warn, :debug, :level

  @_logger = nil

  class << self
    def logger
      return @_logger unless @_logger.nil?

      @_logger = Logger.new $stdout
      @_logger.level = ENV['CEDAR_LOG_LEVEL'] || Logger::INFO
    end

    def suppress_logging
      logger.level = Logger::FATAL
    end
  end
end
