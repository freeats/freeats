# frozen_string_literal: true

class Huntflow::Coworker
  attr_reader :id, :head, :type, :name, :email, :permissions, :user_id

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
    @user_id = params[:member]
    @permissions = params[:permissions]
  end

  def user
    @user ||= Huntflow::User.find_by(id: member)
  end
end
