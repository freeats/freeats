# frozen_string_literal: true

module ActiveStorageBlob
  def build_after_unfurling(*, **kwargs)
    attached_as = kwargs.delete(:attached_as)

    blob = super

    # The initial `blob.key` is a unique secure token
    # https://github.com/rails/rails/blob/main/activestorage/app/models/active_storage/blob.rb#L188
    blob.key =
      if attached_as == "files"
        "#{blob.key}/#{blob.filename}"
      else
        "#{blob.key}/avatar.#{blob.filename.to_s.split('.').last}"
      end

    blob
  end
end
