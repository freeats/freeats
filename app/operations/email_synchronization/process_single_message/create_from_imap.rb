# frozen_string_literal: true

class EmailSynchronization::ProcessSingleMessage::CreateFromImap < ApplicationOperation
  include Dry::Monads[:result, :do]

  option :message, Types::Instance(Imap::Message)
  option :email_thread_id, Types::Coercible::Integer
  option :message_member, Types::Instance(EmailSynchronization::MessageMember)
  option :sent_via, Types::Symbol.enum(:gmail, :hub_compose, :hub_reply)

  def call
    email_message = EmailMessage.create!(
      email_thread_id:,
      timestamp: message.timestamp,
      subject: message.subject,
      plain_body: message.plain_body,
      plain_mime_type: message.plain_mime_type,
      html_body: message.html_body,
      sent_via:,
      message_id: message.message_id,
      in_reply_to: message.in_reply_to || "",
      references: message.references || [],
      autoreply_headers: message.autoreply_headers || {}
    )

    create_message_addresses(email_message, message.from, :from)
    create_message_addresses(email_message, message.to, :to)
    create_message_addresses(email_message, message.cc, :cc)
    create_message_addresses(email_message, message.bcc, :bcc)

    email_message_params = {
      actor_account: message_member.member.account,
      type: message_member.field == :from ? :email_sent : :email_received,
      eventable: email_message,
      performed_at: Time.zone.at(email_message.timestamp).to_datetime
    }

    yield Events::Add.new(params: email_message_params).call

    Success(email_message)
  end

  private

  def create_message_addresses(email_message, addresses, field)
    addresses.map.with_index(1) do |address, index|
      name, email_address =
        Imap::Message
        .parse_address(normalize_address(address))
        .values_at(:name, :address)

      address_params = {
        address: email_address,
        name:,
        field:,
        position: index
      }

      email_message.email_message_addresses.create!(**address_params)
    end
  end

  def normalize_address(address)
    cleared_address = address.delete("\"|<>").split

    if cleared_address.length >= 2
      *name, normalized_address = cleared_address
      "#{name.join(' ')} <#{normalized_address}>"
    else
      "<#{cleared_address.join}>"
    end
  end
end
