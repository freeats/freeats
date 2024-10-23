# frozen_string_literal: true

class MemberNoteMailer < ApplicationMailer
  before_action do
    @note = params[:note]
    @model = @note.note_thread.notable
    @model_name = @model.try(:full_name) || @model.name
    @task_prefix = " on #{@model.taskable_name}" if @model.is_a?(Task) && @model.taskable.present?

    @reply_to = ENV.fetch("MAILER_REPLY_TO", "")

    thread_unique_id = "<note_threads/#{@note.note_thread.id}@#{ENV.fetch('HOST_URL', 'domain')}>"
    headers({ "In-Reply-To" => thread_unique_id, "References" => thread_unique_id })
  end

  def created
    mail(subject: "[#{account_name(@current_account)}] commented on #{@model_name}")
  end

  def mentioned
    mail(subject: "[#{account_name(@current_account)}] commented on #{@model_name}")
  end

  def replied
    mail(subject: "[#{account_name(@current_account)}] commented on #{@model_name}")
  end

  def task_created
    mail(subject: "[#{account_name(@current_account)}] commented on task#{@task_prefix}: " \
                  "#{@model_name}")
  end

  def task_mentioned
    mail(subject: "[#{account_name(@current_account)}] mentioned you on task#{@task_prefix}: " \
                  "#{@model_name}")
  end

  def task_replied
    mail(subject: "[#{account_name(@current_account)}] replied on task#{@task_prefix}: " \
                  "#{@model_name}")
  end
end
