# frozen_string_literal: true

module ActiveStorageAttachment
  extend ActiveSupport::Concern
  include Dry::Monads[:result]

  included do
    has_one :attachment_information,
            foreign_key: :active_storage_attachment_id,
            dependent: :destroy
  end

  def change_cv_status(new_cv_status)
    record_object = record_type.constantize.find(record_id)
    old_cv = new_cv_status ? record_object.cv : self
    transaction do
      old_cv&.attachment_information&.update!(is_cv: false) if new_cv_status

      result =
        if attachment_information
          AttachmentInformations::Change.new(attachment_information:,
                                             params: { is_cv: new_cv_status }).call
        else
          AttachmentInformations::Add.new(params: { active_storage_attachment_id: id,
                                                    is_cv: new_cv_status }).call
        end

      case result
      in Success(attachment_information)
        nil
      in Failure(:attachment_information_invalid, attachment_information)
        record_object.errors.add(:base, attachment_information.errors.full_messages.join(", "))
      end
    end
  end

  def cv?
    return false unless attachment_information

    attachment_information.is_cv
  end
end
