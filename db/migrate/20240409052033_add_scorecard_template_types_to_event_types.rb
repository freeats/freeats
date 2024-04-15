# frozen_string_literal: true

class AddScorecardTemplateTypesToEventTypes < ActiveRecord::Migration[7.1]
  def up
    execute "ALTER TYPE event_type ADD VALUE 'scorecard_template_added';"
    execute "ALTER TYPE event_type ADD VALUE 'scorecard_template_updated';"
  end
end
