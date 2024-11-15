# frozen_string_literal: true

class Task < ApplicationRecord
  acts_as_tenant(:tenant)

  has_and_belongs_to_many :watchers,
                          class_name: "Member",
                          join_table: :tasks_watchers,
                          association_foreign_key: :watcher_id
  has_many :note_threads, as: :notable, dependent: :destroy
  has_many :notes, through: :note_threads
  has_many :events, as: :eventable, dependent: :destroy
  has_one :added_event,
          -> { where(type: :task_added) },
          class_name: "Event",
          foreign_key: :eventable_id,
          inverse_of: false,
          dependent: nil
  belongs_to :taskable, polymorphic: true, optional: true
  belongs_to :assignee, class_name: "Member", optional: true

  enum :status, %i[open closed].index_with(&:to_s)
  enum :repeat_interval, %i[never daily weekly monthly yearly].index_with(&:to_s), suffix: true

  strip_attributes only: :name

  validates :due_date, presence: true
  validates :name, presence: true
  validates :status, presence: true
  validates_with MergedCandidateIsReadOnlyValidator

  scope :past_or_present, -> { where(due_date: ..Time.zone.today) }
  scope :pending, -> { open.past_or_present }
  scope :pending_for, ->(member) { pending.where(assignee: member) }

  def self.grid_scope
    left_joins(:notes)
      .select(
        "tasks.status,
        tasks.name,
        tasks.taskable_type,
        tasks.taskable_id,
        tasks.assignee_id,
        tasks.due_date,
        tasks.id,
        tasks.repeat_interval,
        COUNT (notes.id) AS notes_count"
      ).group("tasks.id")
  end

  def self.default_watchers(taskable)
    case taskable
    when Candidate then [taskable.recruiter]
    when Position then [taskable.recruiter, *taskable.collaborators]
    else []
    end.compact.filter(&:active?).uniq
  end

  def url
    Rails.application.routes.url_helpers.ats_task_url(
      self,
      host: ENV.fetch("HOST_URL", nil),
      protocol: ATS::Application.config.force_ssl ? "https" : "http"
    )
  end

  def overdue?
    due_date.past? && open?
  end

  def repeating?
    !never_repeat_interval?
  end

  def creator
    added_event.actor_account
  end

  def taskable_name
    taskable_type == "Position" ? taskable.name : taskable.full_name
  end

  def activities(since: nil)
    note_events_query =
      Event
      .joins(<<~SQL)
        JOIN notes ON notes.id = events.eventable_id AND events.eventable_type = 'Note'
        JOIN note_threads ON note_threads.id = notes.note_thread_id
      SQL
      .where(note_threads: { notable_id: id, notable_type: "Task" })
    note_events_query = note_events_query.where("performed_at > ?", since) if since

    task_events_query =
      Event
      .joins(<<~SQL)
        JOIN tasks ON tasks.id = events.eventable_id AND events.eventable_type = 'Task'
      SQL
      .where(tasks: { id: })
      .union(note_events_query)
      .includes(
        :eventable,
        actor_account: :member,
        added_watcher: :account,
        removed_watcher: :account
      )
      .order(performed_at: :desc)
    task_events_query = task_events_query.where("performed_at > ?", since) if since
    task_events_query
  end

  def notification_recipients(current_member:)
    (watchers.includes(:account) - [current_member]).filter_map { _1.email_address if _1.active? }
  end
end
