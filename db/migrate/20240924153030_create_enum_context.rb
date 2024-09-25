# frozen_string_literal: true

class CreateEnumContext < ActiveRecord::Migration[7.1]
  def change
    create_enum :access_token_context, %i[member_invitation]
  end
end
