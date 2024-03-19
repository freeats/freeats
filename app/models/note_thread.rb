# frozen_string_literal: true

class NoteThread < ApplicationRecord
  has_many :notes, dependent: :destroy

  has_one :self_ref, class_name: "NoteThread", foreign_key: :id, dependent: nil # rubocop:disable Rails/InverseOf
  has_one :candidate, through: :self_ref, source: :notable, source_type: "Candidate"

  belongs_to :notable, polymorphic: true
end
