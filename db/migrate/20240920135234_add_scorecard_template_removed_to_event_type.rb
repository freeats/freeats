# frozen_string_literal: true

class AddScorecardTemplateRemovedToEventType < ActiveRecord::Migration[7.1]
  def up
    execute <<~SQL
      ALTER TYPE event_type ADD VALUE 'scorecard_template_removed' AFTER 'scorecard_template_added';
    SQL
  end
end
