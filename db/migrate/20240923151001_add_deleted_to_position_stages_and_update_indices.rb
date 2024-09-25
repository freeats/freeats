# frozen_string_literal: true

class AddDeletedToPositionStagesAndUpdateIndices < ActiveRecord::Migration[7.1]
  def change
    add_column :position_stages, :deleted, :boolean, null: false, default: false

    reversible do |dir|
      dir.up do
        execute <<~SQL
          DROP INDEX index_position_stages_on_position_id_and_list_index;
          DROP INDEX index_position_stages_on_position_id_and_name;

          CREATE UNIQUE INDEX index_position_stages_on_position_id_and_list_index
            ON public.position_stages USING btree (position_id, list_index)
            WHERE deleted = false;

          CREATE UNIQUE INDEX index_position_stages_on_position_id_and_name
            ON public.position_stages USING btree (position_id, name)
            WHERE deleted = false;
        SQL
      end

      dir.down do
        execute <<~SQL
          DROP INDEX index_position_stages_on_position_id_and_list_index;
          DROP INDEX index_position_stages_on_position_id_and_name;

          CREATE UNIQUE INDEX index_position_stages_on_position_id_and_list_index
            ON public.position_stages USING btree (position_id, list_index);
          CREATE UNIQUE INDEX index_position_stages_on_position_id_and_name
            ON public.position_stages USING btree (position_id, name);
        SQL
      end
    end
  end
end
