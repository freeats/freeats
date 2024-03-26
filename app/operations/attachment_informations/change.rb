# frozen_string_literal: true

class AttachmentInformations::Change
  include Dry::Monads[:result]

  include Dry::Initializer.define -> do
    option :attachment_information, Types::Instance(AttachmentInformation)
    option :params, Types::Strict::Hash
  end

  def call
    attachment_information.assign_attributes(params)

    if attachment_information.valid?
      attachment_information.save!
      Success(attachment_information)
    else
      Failure[:attachment_information_invalid, attachment_information]
    end
  end
end
