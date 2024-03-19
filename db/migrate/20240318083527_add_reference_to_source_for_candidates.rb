# frozen_string_literal: true

class AddReferenceToSourceForCandidates < ActiveRecord::Migration[7.1]
  def change
    add_reference :candidates, :candidate_source, foreign_key: true
  end
end
