# frozen_string_literal: true

module ActiveStorageAttachment
  extend ActiveSupport::Concern
  include Dry::Monads[:result]

  included do
    has_many :events, as: :eventable, dependent: :destroy
    has_one :attachment_information,
            foreign_key: :active_storage_attachment_id,
            dependent: :destroy
    has_one :added_event,
            -> { where(type: :active_storage_attachment_added) },
            class_name: "Event",
            foreign_key: "eventable_id",
            inverse_of: false,
            dependent: :destroy
  end

  def change_cv_status(actor_account = nil)
    record_object = record_type.constantize.find(record_id)
    old_cv = record_object.cv

    transaction do
      old_cv&.attachment_information&.update!(is_cv: false)

      result =
        if attachment_information
          AttachmentInformations::Change.new(attachment_information:,
                                             params: { is_cv: old_cv != self }).call
        else
          AttachmentInformations::Add.new(params: { active_storage_attachment_id: id,
                                                    is_cv: true }).call
        end

      same_file = old_cv&.blob == blob

      Event.create_changed_event_if_value_changed(
        eventable: record,
        changed_field: "cv",
        old_value: old_cv&.blob&.filename.to_s,
        new_value: same_file ? nil : blob.filename.to_s,
        actor_account:
      )

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

  def remove
    transaction do
      attachment_information&.destroy!
      purge
    end
  end
end
