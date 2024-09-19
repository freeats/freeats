# frozen_string_literal: true

class RenamePositionStatusPassiveToOnHold < ActiveRecord::Migration[7.1]
  def up
    execute <<~SQL
      ALTER TYPE position_status RENAME VALUE 'passive' TO 'on_hold';
    SQL
  end

  def down
    execute <<~SQL
      ALTER TYPE position_status RENAME VALUE 'on_hold' TO 'passive';
    SQL
  end
end
