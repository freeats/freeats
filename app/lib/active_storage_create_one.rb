# frozen_string_literal: true

module ActiveStorageCreateOne
  def find_or_build_blob
    blob = super

    # The initial `blob.key` is a unique secure token
    # https://github.com/rails/rails/blob/main/activestorage/app/models/active_storage/blob.rb#L188
    blob.key =
      if name == "files"
        "uploads/files/#{blob.key}/#{blob.filename}"
      else
        if record.is_a?(ActiveStorage::VariantRecord)
          attachment = record.blob.attachments.first
          object_name = attachment.record_type.downcase
          record_id = attachment.record_id
        else
          object_name = record.class.name.downcase
          record_id = record.id
        end
        "uploads/#{object_name}/#{record_id}/#{blob.key}_#{blob.filename}"
      end
    blob
  end
end
