# frozen_string_literal: true

class Note < ApplicationRecord
  belongs_to :note_thread
end
