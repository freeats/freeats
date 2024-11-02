# frozen_string_literal: true

class ATS::Logger
  PRODUCTION_LOG_LEVEL = ::Logger::INFO

  class ExternalLogger
    attr_reader :logger
    attr_accessor :where

    def initialize(logger:, where:)
      @logger = logger
      @where = where
    end

    def log(...)
      if Rails.env.in?(Sentry.configuration.enabled_environments)
        sentry_log(...)
      else
        stream_log(...)
      end
    end

    private

    def sentry_log(exception_or_message, **payload)
      payload[:where] = where if where.present?
      case exception_or_message
      when String then Sentry.capture_message(exception_or_message, extra: payload)
      when StandardError then Sentry.capture_exception(exception_or_message, extra: payload)
      else
        Sentry.capture_message(exception_or_message.inspect, extra: payload)
      end
    end

    # It could be stdout, log file, both or passed via param stream, see default_stream.
    def stream_log(exception_or_message, **)
      logger.warn(exception_or_message, **)
    end
  end

  attr_reader :logger, :external_logger, :where

  delegate :debug, :info, :warn, :error, :fatal, :unknown, to: :logger

  def initialize(level: nil, where: nil, template: nil, stream: nil)
    level ||= default_level
    template ||= default_template
    stream ||= default_stream
    default_options = { template:, level:, stream:, colorize: true }
    @logger = Dry.Logger(:hub, **default_options)
    @logger.context[:where] = where
    external_logger =
      Dry.Logger(:hub, **default_options.merge(template: external_template(template)))
    external_logger.context[:where] = where
    if Rails.env.development? || ENV["LOG_TO_STDOUT"].present?
      @logger.add_backend(stream: $stdout)
      external_logger.add_backend(stream: $stdout)
    end
    @external_logger = ExternalLogger.new(logger: external_logger, where:)
  end

  def external_log(exception_or_message = nil, **)
    external_logger.log(exception_or_message, **)
  end

  def tagged(new_where)
    old_where = @logger.context[:where]
    @logger.context[:where] = new_where
    @external_logger.where = new_where
    yield self
  ensure
    @logger.context[:where] = old_where
    @external_logger.where = old_where
  end

  def debug?
    logger.level >= ::Logger::DEBUG
  end

  def info?
    logger.level >= ::Logger::INFO
  end

  def warn?
    logger.level >= ::Logger::WARN
  end

  def error?
    logger.level >= ::Logger::ERROR
  end

  def fatal?
    logger.level >= ::Logger::FATAL
  end

  def unknown?
    logger.level >= ::Logger::UNKNOWN
  end

  private

  def default_level
    if Rails.env.production?
      PRODUCTION_LOG_LEVEL
    else
      ::Logger::DEBUG
    end
  end

  def default_stream
    if Rails.env.production? || Rails.env.staging?
      # This logic is special-cased for production and copied to be the same as in
      # config/environments/production.rb.
      if ENV["RAILS_LOG_TO_STDOUT"].present?
        $stdout
      else
        Rails.root.join("log/production.log")
      end
    elsif Rails.env.test?
      Rails.root.join("log/test.log")
    elsif Rails.env.development?
      Rails.root.join("log/development.log")
    else
      raise ArgumentError, "Unknown Rails environment '#{Rails.env}'"
    end
  end

  def default_template
    if Rails.env.production?
      :details
    else
      # Template is impossible to change after the object has been created, it is necessary
      # to put empty `[]` if `where` is absent in order to support the `tagged` method.
      "[%<severity>s] [<magenta>%<where>s</magenta>] %<message>s %<payload>s"
    end
  end

  def external_template(template)
    "[<yellow>EXTERNAL</yellow>] #{template}"
  end
end
