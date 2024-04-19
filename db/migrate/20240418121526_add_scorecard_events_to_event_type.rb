# frozen_string_literal: true

class AddScorecardEventsToEventType < ActiveRecord::Migration[7.1]
  def up
    execute <<~SQL
      ALTER TYPE event_type ADD VALUE 'scorecard_added' BEFORE 'scorecard_template_added';
      ALTER TYPE event_type ADD VALUE 'scorecard_updated' BEFORE 'scorecard_template_added';
    SQL
  end
end
