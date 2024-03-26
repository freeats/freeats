# frozen_string_literal: true

class AttachmentInformation < ApplicationRecord
  belongs_to :active_storage_attachment, class_name: "ActiveStorage::Attachment"
end
