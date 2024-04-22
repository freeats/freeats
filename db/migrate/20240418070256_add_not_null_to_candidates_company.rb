# frozen_string_literal: true

class AddNotNullToCandidatesCompany < ActiveRecord::Migration[7.1]
  def change
    change_column_default(:candidates, :company, from: nil, to: "")
    change_column_null(:candidates, :company, false, "")
  end
end
