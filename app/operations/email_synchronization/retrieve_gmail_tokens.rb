# frozen_string_literal: true

class EmailSynchronization::RetrieveGmailTokens < ApplicationOperation
  include Dry::Monads[:result, :do]

  option :current_member, Types::Instance(Member)
  option :code, Types::Strict::String
  option :redirect_uri, Types::Strict::String

  def call
    access_token, refresh_token = yield fetch_tokens
    linked_email_address = yield retrieve_email_address(access_token)
    yield check_email_same_as_current(current_member.email_address, linked_email_address)

    persist_tokens(access_token, refresh_token)
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

  def check_email_same_as_current(current_email, retrieved_email)
    return Success() if current_email == retrieved_email

    Failure[:emails_not_match, retrieved_email]
  end

  def persist_tokens(token, refresh_token)
    current_member.update!(token:, refresh_token:)
    Success()
  rescue ActiveRecord::RecordInvalid => e
    Failure[:new_tokens_are_not_saved, e]
  end
end
