# frozen_string_literal: true

class AlterPositionAndDelayInDaysMustBeValidConstraint < ActiveRecord::Migration[7.1]
  def up
    execute <<~SQL
      ALTER TABLE sequence_template_stages
      ADD CONSTRAINT position_and_delay_in_days_must_be_valid
      CHECK (
        (position = 1 AND delay_in_days IS NULL) OR
        (position > 1 AND delay_in_days IS NOT NULL AND delay_in_days > 0)
      );
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE sequence_template_stages DROP CONSTRAINT position_and_delay_in_days_must_be_valid;
    SQL
  end
end
