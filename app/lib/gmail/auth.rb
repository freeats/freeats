# frozen_string_literal: true

require "multi_json"
require "signet/oauth_2/client"

module Gmail::Auth
  class ServerError < ::Gmail::Error; end
  class ClientError < ::Gmail::Error; end
  class AuthorizationError < ClientError; end

  class << self
    def authorization_uri(redirect_uri:)
      client = signet_client
      client.redirect_uri = redirect_uri
      client.authorization_uri.to_s
    end

    def fetch_access_and_refresh_tokens(code:, redirect_uri:)
      client = signet_client
      client.code = code
      client.redirect_uri = redirect_uri
      fetch_access_token(client)
      [client.access_token, client.refresh_token]
    end

    private

    def signet_client
      Signet::OAuth2::Client.new(
        authorization_uri: "https://accounts.google.com/o/oauth2/auth",
        token_credential_uri: "https://oauth2.googleapis.com/token",
        client_id: Rails.application.credentials.gmail_linking.client_id!,
        client_secret: Rails.application.credentials.gmail_linking.client_secret!,
        scope: <<~TEXT,
          https://mail.google.com
          email
        TEXT
        additional_parameters: { approval_prompt: :force }
      )
    end

    def fetch_access_token(client)
      client.fetch_access_token!
    rescue Signet::UnsafeOperationError, Signet::ParseError,
           Signet::MalformedAuthorizationError => e
      raise ClientError, e.message
    rescue Faraday::Error, Signet::RemoteServerError, Signet::UnexpectedStatusError,
           MultiJson::ParseError => e
      raise ServerError, e.message
    rescue Signet::AuthorizationError => e
      raise AuthorizationError, "#{e.message}, request: #{e.request}, response: #{e.response}"
    end
  end
end
