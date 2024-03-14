# frozen_string_literal: true

class Candidate < ApplicationRecord
  has_one_attached :avatar do |attachable|
    attachable.variant(:medium, resize_to_fill: [400, 400], preprocessed: true)
  end

  has_many_attached :files

  def destroy_file_attachment(attachment)
    transaction do
      AttachmentInformation
        .find_by(active_storage_attachment_id: attachment.id)
        &.destroy

      attachment.purge
    end
  end
end
