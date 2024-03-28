# frozen_string_literal: true

class CreateScorecardTemplateQuestions < ActiveRecord::Migration[7.1]
  def change
    create_table :scorecard_template_questions do |t|
      t.references :scorecard_template, null: false, foreign_key: true
      t.string :question, null: false
      t.integer :list_index, null: false

      t.timestamps

      t.index %i[scorecard_template_id list_index], unique: true
    end
  end
end
