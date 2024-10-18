# frozen_string_literal: true

class EmailThread < ApplicationRecord
  acts_as_tenant(:tenant)

  DATE_RANGE_TYPES = [Date, DateTime, ActiveSupport::TimeWithZone, NilClass].freeze

  has_many :messages,
           -> { order(timestamp: :desc) },
           dependent: :destroy,
           inverse_of: :email_thread,
           class_name: "EmailMessage"
  has_many :email_message_addresses, through: :messages

  def self.get_threads_with_addresses(email_address:, time_range: (nil..nil))
    if !time_range.is_a?(Range) ||
       DATE_RANGE_TYPES.exclude?(time_range.begin.class) ||
       DATE_RANGE_TYPES.exclude?(time_range.end.class)
      raise ArgumentError, ":time_range should be a Range of #{DATE_RANGE_TYPES} types"
    end
    return none if email_address.blank?

    email_addresses = Array(email_address)
    address_query = <<~SQL
      email_message_addresses.address IN (
        SELECT addr::citext FROM (
      VALUES #{(['(?)'] * email_addresses.size).join(', ')}) AS t(addr))
    SQL
    joins(messages: :email_message_addresses)
      .where(address_query, *email_addresses)
      .where(
        "tsrange(:start_date, :end_date) @> to_timestamp(email_messages.timestamp)::timestamp",
        start_date: time_range.begin,
        end_date: time_range.end
      ).distinct
  end

  def candidates_in_thread
    @candidates_in_thread ||= Candidate.with_emails(email_message_addresses.pluck(:address))
  end
end
