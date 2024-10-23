# frozen_string_literal: true

class AttachmentInformations::Add < ApplicationOperation
  include Dry::Monads[:result]

  option :params, Types::Strict::Hash

  def call
    attachment_information = AttachmentInformation.new
    attachment_information.assign_attributes(params)

    if attachment_information.valid?
      attachment_information.save!
      Success(attachment_information)
    else
      Failure[:attachment_information_invalid, attachment_information]
    end
  end
end
