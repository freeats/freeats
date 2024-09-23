# frozen_string_literal: true

module ActiveStorageCreateOne
  # https://github.com/rails/rails/blob/main/activestorage/lib/active_storage/attached/changes/create_one.rb#L68
  # Copied method to pass an additional argument to `build_after_unfurling`
  def find_or_build_blob
    case attachable
    when ActiveStorage::Blob
      attachable
    when ActionDispatch::Http::UploadedFile
      ActiveStorage::Blob.build_after_unfurling(
        io: attachable.open,
        filename: attachable.original_filename,
        content_type: attachable.content_type,
        record:,
        service_name: attachment_service_name,
        attached_as: name
      )
    when Rack::Test::UploadedFile
      ActiveStorage::Blob.build_after_unfurling(
        io: attachable.respond_to?(:open) ? attachable.open : attachable,
        filename: attachable.original_filename,
        content_type: attachable.content_type,
        record:,
        service_name: attachment_service_name,
        attached_as: name
      )
    when Hash
      ActiveStorage::Blob.build_after_unfurling(
        **attachable.reverse_merge(
          record:,
          service_name: attachment_service_name,
          attached_as: name
        ).symbolize_keys
      )
    when String
      ActiveStorage::Blob.find_signed!(attachable, record:)
    when File
      ActiveStorage::Blob.build_after_unfurling(
        io: attachable,
        filename: File.basename(attachable),
        record:,
        service_name: attachment_service_name,
        attached_as: name
      )
    when Pathname
      ActiveStorage::Blob.build_after_unfurling(
        io: attachable.open,
        filename: File.basename(attachable),
        record:,
        service_name: attachment_service_name,
        attached_as: name
      )
    else
      raise(
        ArgumentError,
        "Could not find or build blob: expected attachable, " \
        "got #{attachable.inspect}"
      )
    end
  end
end
