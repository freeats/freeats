# frozen_string_literal: true

module Huntflow::API
  class NoTokenError < Huntflow::HuntflowError; end
  class InvalidTokenError < Huntflow::HuntflowError; end
  class ServerError < Huntflow::HuntflowError; end
  class TooManyRequestsError < Huntflow::HuntflowError; end
  class NotFoundError < Huntflow::HuntflowError; end

  API_MODE = ENV.fetch("HUNTFLOW_API_MODE", "production")

  BASE_URI = "https://api.huntflow.ru/v2/"
  API_TOKEN = Rails.application.credentials.huntflow.api_token
  ACCOUNT_ID = Rails.application.credentials.huntflow.account_id

  class << self
    def get(path, params = {})
      request(Net::HTTP::Get, path, params)
    end

    private

    def request(method, path, params)
      if Rails.env.development? && API_MODE != "production"
        return { "data" => { "id" => rand(100) } }
      end

      raise NoTokenError, "Huntflow api token is absent." if API_TOKEN.blank?

      uri = URI.join(BASE_URI, path)
      headers = {
        "Content-Type" => "application/json",
        "Authorization" => "Bearer #{API_TOKEN}"
      }

      req =
        if method == Net::HTTP::Get
          uri.query = URI.encode_www_form(params)
          method.new(uri.request_uri, headers)
        else
          req = method.new(uri.request_uri, headers)
          req.body = params.to_json
          req
        end
      Rails.logger.debug { "#{method::METHOD} #{uri}" }
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      retries = 0
      begin
        preventing_ratelimit_exhaustion
        process_response(http.request(req))
      rescue ServerError
        raise unless (retries += 1) <= 3

        sleep 1
        retry
      rescue TooManyRequestsError
        raise unless (retries += 1) <= 3

        sleep 2
        retry
      end
    end

    def process_response(response)
      if response.is_a?(Net::HTTPSuccess)
        if response.header["x-ratelimit-remaining"].presence
          @ratelimit_remaining = response.header["x-ratelimit-remaining"].to_i
        end
        return response.body if response.content_type == "application/pdf"

        return JSON.parse(response.body)
      end

      if response.is_a?(Net::HTTPUnauthorized)
        raise InvalidTokenError,
              "Huntflow token is invalid."
      end

      if response.is_a?(Net::HTTPTooManyRequests)
        raise TooManyRequestsError,
              "Huntflow rate limit is exhausted."
      end
      if response.is_a?(Net::HTTPServerError)
        raise ServerError,
              "Huntflow is unresponsive, please try again later."
      end
      if response.is_a?(Net::HTTPNotFound)
        raise NotFoundError,
              "Entity is not found."
      end

      raise Huntflow::HuntflowError, response.msg
    rescue JSON::ParserError
      raise Huntflow::HuntflowError, response.body.to_s
    end

    def preventing_ratelimit_exhaustion
      sleep 2 if @ratelimit_remaining && @ratelimit_remaining <= 3
    end
  end
end
