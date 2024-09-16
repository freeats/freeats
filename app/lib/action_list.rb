# frozen_string_literal: true

#
# The ActionList is a mechanism for sequentially performing actions on models.
#
# How to use
#
# First, you need to initialize the instance of the `ActionList` object
# and pass necessary parameters to the constructor.
#
#     action_list = ActionList.new(
#       target_candidate_id:,
#       actor_account_id:,
#       logger: ATS::Logger.new(where: "tag")
#     )
#
#
# Next, should to put the model for which you want to do a certain action
# in the `action_list` using one of the helper methods and `add_records` method
# (or operator `<<`).
#
#     action_list << ActionList.save_records(changed_record)
#
# After all, when all necessary actions was added,
# should call `execute_actions` to perform all actions.
#
#     action_list.execute_actions
#
# Helper methods
#
# Methods of class which returns hash for creating understandable for `ActionList` actions.
#
# - `ActionList.save_record(record)` - to call `save!` for the model.
#
# - `ActionList.destroy_record(record)` - to call `destroy!` for the model.
#
# - `ActionList.fill_event(event)` - to overwrite `eventable_id` and `actor_account_id`
#                                    and call `save!`.
#
class ActionList
  # This is a value that indicates that no changes should be recorded to ActionList.
  NONE = :_action_list_none_value

  attr_reader :target_candidate_id, :actor_account_id, :changeset, :logger

  def self.save_record(record)
    { save: record }
  end

  def self.destroy_record(record)
    { destroy: record }
  end

  def self.fill_event(event)
    { event_to_fill: event }
  end

  def initialize(target_candidate_id:, actor_account_id:, logger:)
    @target_candidate_id = target_candidate_id
    @actor_account_id = actor_account_id
    @records = []
    @changeset = {}
    @logger = logger
  end

  def execute_actions
    @records.each do |record|
      case record
      in { save: }
        logger.debug(save:)
        save_record(save)
      in { destroy: }
        logger.debug(destroy:)
        destroy_record(destroy)
      in { event_to_fill: }
        record = fill_event(event_to_fill)
        logger.debug(save: record)
        save_record(record)
      end
    end
  end

  def add_records(records_and_actions)
    return if records_and_actions == NONE || records_and_actions.empty?

    array_of_records_and_actions =
      case records_and_actions
      when Array then records_and_actions
      when Hash then [records_and_actions]
      else
        raise ArgumentError, "Cannot add #{records_and_actions.inspect} to records"
      end

    array_of_records_and_actions.each do |record_and_action|
      action, record = record_and_action.first
      logger.debug(add: action, record:)
    end
    @records.push(*array_of_records_and_actions)
  end

  def <<(...)
    add_records(...)
  end

  def add_field_and_records(field_name, value, records = nil)
    if value == NONE
      logger.debug(omit_field: field_name)
    else
      logger.debug(add_field: field_name, value:, with_records?: records.present?)
      @changeset[field_name] = value
      self << records if records.present?
    end
    value
  end

  def []=(field_name, value)
    if value == NONE
      logger.debug(omit_field: field_name)
    else
      logger.debug(add_field: field_name, value:)
      @changeset[field_name] = value
    end
  end

  def [](field_name)
    # TODO: make this work. Currently the problem is that every user of this method expects `nil`
    # when the field is not set and doesn't distinguish between "not set" and "set to nil".
    # if @changeset.key?(field_name)
    #   @changeset[field_name]
    # else
    #   NONE
    # end
    @changeset[field_name]
  end

  def find_records(action, object_class)
    @records
      .filter { _1.keys.first == action && _1.values.first.is_a?(object_class) }
      .map { _1[action] }
  end

  def changed?(field_name)
    @changeset.key?(field_name)
  end

  private

  def save_record(record)
    case record
    when Event
      # There will be many of them and we want to do it fast + on every event save
      # happens an update of the candidate's last_activity_at field, we want to avoid
      # unnecessary work here, by using `insert` we don't call any model hooks.
      # rubocop:disable Rails/SkipsModelValidations
      if record.persisted?
        record.update_columns(record.attributes.except("created_at", "updated_at"))
      else
        raise ArgumentError, "Event for insert must not have ID" unless record.id.nil?

        performed_at = record.performed_at.present? ? "" : "performed_at"

        Event.insert!(
          record.attributes.except("id", performed_at, "created_at", "updated_at")
        )
      end
      # rubocop:enable Rails/SkipsModelValidations
    else
      record.save!
    end
  rescue ActiveRecord::RecordNotSaved => e
    logger.external_log(e, record_attributes: record.attributes)
    raise
  end

  def destroy_record(record)
    record.destroy!
  end

  def fill_event(event)
    event.eventable_id = target_candidate_id
    event.eventable_type = "Candidate"
    event.actor_account_id = actor_account_id
    event
  end
end
