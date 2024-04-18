# frozen_string_literal: true

class EmailSynchronization::RetrieveGmailTokens
  include Dry::Monads[:result, :do]

  include Dry::Initializer.define -> do
    option :current_member, Types::Instance(Member)
    option :code, Types::Strict::String
    option :redirect_uri, Types::Strict::String
  end

  def call
    access_token, refresh_token = yield fetch_tokens
    email_address = yield retrieve_email_address(access_token)
    yield persist_tokens(email_address, access_token, refresh_token)
    Success()
  end

  private

  def fetch_tokens
    Success(Gmail::Auth.fetch_access_and_refresh_tokens(code:, redirect_uri:))
  rescue Gmail::Auth::ServerError, Gmail::Auth::ClientError => e
    Failure[:failed_to_fetch_tokens, e]
  end

  def retrieve_email_address(access_token)
    userinfo_response = Faraday.get(
      "https://www.googleapis.com/userinfo/v2/me",
      nil,
      { "Authorization" => "Bearer #{access_token}" }
    )
    raise "Unexpected response status" unless userinfo_response.status == 200

    userinfo = JSON.parse(userinfo_response.body)

    Success(userinfo["email"])
  rescue RuntimeError, Faraday::Error, JSON::JSONError => e
    Failure[:failed_to_retrieve_email_address, e]
  end

  def persist_tokens(address, token, refresh_token)
    member_email_address = current_member.email_addresses.create_or_find_by!(address:)
    member_email_address.update!(token:, refresh_token:)
    Success()
  rescue ActiveRecord::RecordInvalid => e
    Failure[:invalid_member_email_address, e]
  end
end
