# frozen_string_literal: true

class Tenant < ApplicationRecord
  enum locale: %i[en ru].index_with(&:to_s)
end
