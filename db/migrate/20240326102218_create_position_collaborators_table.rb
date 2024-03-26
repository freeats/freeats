# frozen_string_literal: true

class CreatePositionCollaboratorsTable < ActiveRecord::Migration[7.1]
  def change
    create_table :positions_collaborators, id: false do |t|
      t.references :position, foreign_key: true, null: false, index: false
      t.references :collaborator, foreign_key: { to_table: :members }, null: false, index: false

      t.index %i[collaborator_id position_id], unique: true
    end
  end
end
