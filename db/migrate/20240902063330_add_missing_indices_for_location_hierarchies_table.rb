# frozen_string_literal: true

class AddMissingIndicesForLocationHierarchiesTable < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    add_index :location_hierarchies, :path, using: "gist",
                                            opclass: "gist_ltree_ops(siglen=16)",
                                            name: "index_location_hierarchies_on_path_using_gist_16"
  end
end
