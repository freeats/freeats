# frozen_string_literal: true

class Settings::Recruitment::DisqualifyReasons::BulkUpdate < ApplicationOperation
  include Dry::Monads[:result, :do]

  option :disqualify_reasons_params,
         Types::Strict::Array.of(
           Types::Strict::Hash.schema(
             id?: Types::Strict::String,
             title: Types::Strict::String,
             description: Types::Strict::String
           )
         )

  def call
    new_disqualify_reasons, disqualify_reasons_for_deleting =
      yield prepare_disqualify_reasons(disqualify_reasons_params)
    DisqualifyReason.transaction do
      yield destroy_disqualify_reason(disqualify_reasons_for_deleting:)
      yield save_disqualify_reasons(new_disqualify_reasons)
      yield reassign_correct_indices(new_disqualify_reasons)
    end

    Success()
  end

  private

  def destroy_disqualify_reason(disqualify_reasons_for_deleting:)
    return Success() if disqualify_reasons_for_deleting.blank?

    DisqualifyReason.where(id: disqualify_reasons_for_deleting.map(&:id))
                    .map { _1.update!(deleted: true) }
    Success()
  rescue StandardError => e
    Failure[:deletion_failed, e]
  end

  def prepare_disqualify_reasons(disqualify_reasons_params)
    old_disqualify_reasons = DisqualifyReason.not_deleted.to_a

    new_disqualify_reasons =
      disqualify_reasons_params.map.with_index do |new_disqualify_reason, index|
        list_index = -index - 1
        title = new_disqualify_reason[:title]
        description = new_disqualify_reason[:description]
        id = new_disqualify_reason[:id].to_i if new_disqualify_reason[:id].present?

        if id.blank?
          DisqualifyReason.new(title:, description:, list_index:)
        else
          disqualify_reason = old_disqualify_reasons.find { _1.id == id }
          unless disqualify_reason
            return Failure[:disqualify_reason_not_found,
                           "Disqualify reason with id #{id} not found."]
          end

          if disqualify_reason.title.in?(DisqualifyReason::MANDATORY_REASONS) &&
             !title.in?(DisqualifyReason::MANDATORY_REASONS) ||
             !disqualify_reason.title.in?(DisqualifyReason::MANDATORY_REASONS) &&
             title.in?(DisqualifyReason::MANDATORY_REASONS)
            return Failure[:disqualify_reason_cannot_be_changed]
          else
            disqualify_reason.title = title
            disqualify_reason.description = description
            disqualify_reason.list_index = list_index
            disqualify_reason
          end
        end
      end

    disqualify_reasons_for_deleting = old_disqualify_reasons.filter do |disqualify_reason|
      new_disqualify_reasons.pluck(:id).exclude?(disqualify_reason.id)
    end
    if disqualify_reasons_for_deleting.any? { _1.title.in?(DisqualifyReason::MANDATORY_REASONS) }
      return Failure[:disqualify_reason_cannot_be_changed]
    end

    Success[new_disqualify_reasons, disqualify_reasons_for_deleting]
  rescue ActiveRecord::RecordNotFound => e
    Failure[:disqualify_reason_not_found, e]
  end

  def save_disqualify_reasons(disqualify_reasons)
    disqualify_reasons.map(&:save!)

    Success()
  rescue StandardError => e
    Failure[:invalid_disqualify_reasons, e]
  end

  def reassign_correct_indices(disqualify_reasons)
    disqualify_reasons.map do |reason|
      reason.update!(list_index: reason.list_index.abs)
    end

    Success()
  rescue StandardError => e
    Failure[:invalid_disqualify_reasons, e]
  end
end
