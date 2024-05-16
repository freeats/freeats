# frozen_string_literal: true

require "test_helper"

class EmailSynchronization::ProcessSingleMessage::StopSequencesTest < ActiveSupport::TestCase
  include Dry::Monads[:result]
  include ActionMailer::TestHelper

  StopSequences = EmailSynchronization::ProcessSingleMessage::StopSequences

  setup do
    @email_message = email_messages(:john_msg1)
    @message_member =
      EmailSynchronization::MessageMember.new(field: :to, member: members(:employee_member))
    @sequence = sequences(:ruby_position_john)

    assert_equal @sequence.status, "running"
  end

  test "should stop sequence if unsuccessful_delivery_reason is present" do
    unsuccessful_delivery_reason = "some_reason"
    params = {
      email_message: @email_message,
      message_member: @message_member,
      unsuccessful_delivery_reason:,
      is_auto_replied: false
    }

    result = StopSequences.new(**params).call

    assert_equal @sequence.reload.status, "stopped"
    # TODO: uncomment when sequence stop event will be implemented.
    # assert_equal @sequence.events.last.properties["reason"], unsuccessful_delivery_reason
    assert_equal result, Success(:failed_delivery_sequences_stopped)
  end

  test "should stop sequence if message auto replied" do
    params = {
      email_message: @email_message,
      message_member: @message_member,
      unsuccessful_delivery_reason: nil,
      is_auto_replied: true
    }

    result = StopSequences.new(**params).call

    assert_equal @sequence.reload.status, "stopped"
    # TODO: uncomment when sequence stop event will be implemented.
    # assert_equal @sequence.events.last.properties["reason"], "auto_reply"
    assert_equal result, Success(:auto_reply_sequences_stopped)
  end

  test "should stop sequence with status replied if reply with recent timestamp is received" do
    @email_message.update!(timestamp: Time.zone.now.to_i + 1)

    assert_operator @email_message.timestamp, :>, @sequence.created_at.to_i

    params = {
      email_message: @email_message,
      message_member: @message_member,
      unsuccessful_delivery_reason: nil,
      is_auto_replied: false
    }

    result = StopSequences.new(**params).call

    assert_equal @sequence.reload.status, "replied"
    # TODO: uncomment when sequence stop event will be implemented.
    # assert_equal @sequence.events.last.type, "sequence_replied"
    assert_equal result, Success()
  end

  test "should mark candidate email addresses as outdated if the address is not " \
       "found and have email messages sent to us" do
    candidate_email_address = candidate_email_addresses(:john_email_address)
    address_not_found_message = build(
      :email_message,
      from: "mailer-daemon@googlemail.com",
      plain_body: "** Address not found ** Your message wasn't delivered to #{candidate_email_address.address} " \
                  "because the address couldn't be found, or is unable to receive mail."
    )

    params = {
      email_message: address_not_found_message,
      message_member: @message_member,
      unsuccessful_delivery_reason: "address_not_found",
      is_auto_replied: true
    }

    assert_equal EmailMessage.messages_from_addresses(from: candidate_email_address.address).length, 1
    assert_not_equal candidate_email_address.status, "outdated"

    StopSequences.new(**params).call

    assert_equal candidate_email_address.reload.status, "outdated"
  end

  test "should mark candidate email addresses as invalid if the address is not " \
       "found and haven't email messages sent to us" do
    candidate_email_address = candidate_email_addresses(:jake_email_address)
    address_not_found_message = build(
      :email_message,
      from: "mailer-daemon@googlemail.com",
      plain_body: "** Address not found ** Your message wasn't delivered to #{candidate_email_address.address} " \
                  "because the address couldn't be found, or is unable to receive mail."
    )

    params = {
      email_message: address_not_found_message,
      message_member: @message_member,
      unsuccessful_delivery_reason: "address_not_found",
      is_auto_replied: true
    }

    @email_message.destroy!

    assert_equal EmailMessage.messages_from_addresses(from: candidate_email_address.address).length, 0
    assert_not_equal candidate_email_address.status, "invalid"

    StopSequences.new(**params).call

    assert_equal candidate_email_address.reload.status, "invalid"
  end
end
