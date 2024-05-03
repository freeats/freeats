# frozen_string_literal: true

class Candidates::StopSequences
  include Dry::Monads[:result]

  include Dry::Initializer.define -> do
    option :candidate, Types.Instance(Candidate)
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
    ActiveRecord::Base.transaction do
      Sequence.to_stop(candidate.all_emails).each do |sequence|
        case Sequences::Stop.new(
          sequence:,
          with_status:,
          with_exited_at:,
          event_properties:
        ).call
        in Success() |
           Failure[:sequence_invalid, _e]
          nil
        end
      end
    end

    Success()
  end
end
