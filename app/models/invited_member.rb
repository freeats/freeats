# frozen_string_literal: true

class InvitedMember
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :name, :string
  attribute :email, :string
  attribute :access_level, :string
  attribute :created_at, :datetime
  attribute :id, :integer

  def param_key
    "invited_user"
  end

  def avatar
    nil
  end
end
