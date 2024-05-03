# frozen_string_literal: true

class Sequences::Stop
  include Dry::Monads[:result, :do]

  include Dry::Initializer.define -> do
    option :sequence, Types.Instance(Sequence)
    option :with_status,
           Types::Strict::Symbol.enum(*Sequence.statuses.keys.map(&:to_sym)),
           default: -> { :stopped }
    option :with_exited_at, Types::Instance(ActiveSupport::TimeWithZone), default: -> {}
    option :event_properties,
           Types::Strict::Hash.schema(
             reason?: Types::Strict::String,
             from?: Types::Strict::String
           ),
           default: -> { {} }
  end

  def call
    return Success() if sequence.status != "running"

    exited_at =
      if with_status == :replied || with_exited_at.blank?
        Time.zone.now
      else
        with_exited_at
      end

    sequence.assign_attributes(status: with_status, exited_at:)

    ActiveRecord::Base.transaction do
      yield save_sequence(sequence)
      # TODO: Add event
    end

    Success()
  end

  private

  def save_sequence(sequence)
    sequence.save!
    Success(sequence)
  rescue ActiveRecord::RecordInvalid => e
    logger = ATS::Logger.new(where: "Sequences::Stop#save_sequence")
    logger.external_log(e, extra: { sequence_id: sequence.id })

    Failure[:sequence_invalid, sequence.errors.full_messages]
  end
end
