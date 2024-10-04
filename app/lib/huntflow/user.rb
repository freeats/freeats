# frozen_string_literal: true

class Huntflow::User
  attr_reader :id, :head, :type, :name, :email, :permissions

  # Total number of users: 53
  def self.find_by(id:)
    new(Huntflow::API.get("accounts/#{Huntflow::API::ACCOUNT_ID}/users/#{id}").deep_symbolize_keys)
  end

  def self.index
    Huntflow::API
      .get("accounts/#{Huntflow::API::ACCOUNT_ID}/coworkers")["items"]
      .map { new(_1.deep_symbolize_keys) }
  end

  def initialize(params)
    @id = params[:id]
    @head = params[:head]
    @type = params[:type]
    @name = params[:name]
    @email = params[:email]
    @permissions = params[:permissions]
  end
end
