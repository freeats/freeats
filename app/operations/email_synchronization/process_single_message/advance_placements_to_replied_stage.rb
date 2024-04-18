# frozen_string_literal: true

class EmailSynchronization::ProcessSingleMessage::AdvancePlacementsToRepliedStage
  include Dry::Monads[:result, :do]

  include Dry::Initializer.define -> do
    option :email_message, Types::Instance(EmailMessage)
  end

  def call
    email_message.email_thread.candidates_in_thread.each do |candidate|
      candidate
        .placements
        .joins(:position_stage)
        .where(position_stage: { name: "Contacted" }, status: :qualified)
        .find_each do |placement|
        yield Placements::ChangeStage.new(
          new_stage: "Replied",
          placement:
        ).call
      end
    end
    Success()
  end
end
