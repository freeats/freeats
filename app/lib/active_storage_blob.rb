# frozen_string_literal: true

module ActiveStorageBlob
  def build_after_unfurling(*args, **kwargs)
    blob = super(*args, **kwargs)
    record = kwargs[:record]
    filename = "#{blob.key}_#{kwargs[:filename]}"

    blob.key =
      if record.is_a?(ActiveStorage::VariantRecord)
        attachment = record.blob.attachments.first
        "uploads/#{attachment.record_type.downcase}/#{attachment.record_id}/#{filename}"
      else
        "uploads/#{record.class.name.downcase}/#{record.id}/#{filename}"
      end

    blob
  end
end
