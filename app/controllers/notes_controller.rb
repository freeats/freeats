# frozen_string_literal: true

class NotesController < AuthorizedController
  include Dry::Monads[:result]

  before_action :set_note, only: %i[update destroy show_edit_view show_show_view
                                    add_reaction remove_reaction]
  before_action :set_all_active_members,
                only: %i[create reply update destroy show_show_view]
  before_action :authorize!, only: %i[create reply]
  before_action -> { authorize!(@note) },
                only: %i[update destroy show_edit_view show_show_view
                         add_reaction remove_reaction]

  def create
    case Notes::Add.new(
      text: note_params.require(:text),
      note_thread_params: note_params.require(:note_thread).to_h.deep_symbolize_keys,
      actor_account: current_account
    ).call
    in Success(note)
      note_thread =
        NoteThread
        .includes(:members, notes: %i[member reacted_members])
        .find(note.note_thread_id)

      notes_stream = build_turbo_stream_notes(note_thread:, action: :create)
      if note_thread.notable_type == "Task"
        since = params[:render_time].to_datetime
        latest_activities_stream = add_turbo_stream_latest_activities(note_thread:, since:)
      end

      render_turbo_stream([notes_stream, latest_activities_stream])
    in Failure[:note_invalid, _e] | Failure[:note_not_unique, _e] |
       Failure[:note_thread_invalid, _e] | Failure[:note_thread_not_unique, _e]
      render_error _e, status: :unprocessable_entity
    end
  end

  def reply
    case Notes::Add.new(
      text: note_params.require(:text),
      note_thread_params: note_params.require(:note_thread).to_h.deep_symbolize_keys,
      actor_account: current_account,
      add_hidden_thread_members: params[:mentioned_in_hidden_thread_modal] == "1"
    ).call
    in Success(note)
      note_thread =
        NoteThread
        .includes(:members, notes: %i[member reacted_members])
        .find(note.note_thread_id)

      notes_stream = build_turbo_stream_notes(note_thread:, action: :reply, expanded: true)
      if note_thread.notable_type == "Task"
        since = params[:render_time].to_datetime
        latest_activities_stream = add_turbo_stream_latest_activities(note_thread:, since:)
      end

      render_turbo_stream([notes_stream, latest_activities_stream])
    in Failure(:mentioned_in_hidden_thread, forbidden_member_ids)
      render_mentioned_in_hidden_thread_modal(action: :reply, forbidden_member_ids:)
    in Failure[:note_invalid, _e] | Failure[:note_not_unique, _e] |
       Failure[:note_thread_invalid, _e] | Failure[:note_thread_not_unique, _e]
      render_error _e, status: :unprocessable_entity
    end
  end

  def update
    case Notes::Change.new(
      id: params[:id],
      text: note_update_params[:text],
      actor_account: current_account,
      add_hidden_thread_members: params[:mentioned_in_hidden_thread_modal] == "1"
    ).call
    in Success(note)
      note_thread =
        NoteThread
        .includes(:members, notes: %i[member reacted_members])
        .find(note.note_thread_id)

      expanded = note != note_thread.notes.min_by(&:created_at)

      notes_stream = build_turbo_stream_notes(note_thread:, action: :update, expanded:)
      if note_thread.notable_type == "Task"
        since = params[:render_time].to_datetime
        event_id = note.events.where(type: "note_added").last.id
        updates_stream = update_turbo_stream_activity(event_id)
        latest_activities_stream = add_turbo_stream_latest_activities(note_thread:, since:)
      end

      render_turbo_stream([notes_stream, updates_stream, latest_activities_stream])
    in Failure(:mentioned_in_hidden_thread, forbidden_member_ids)
      render_mentioned_in_hidden_thread_modal(action: :update, forbidden_member_ids:)
    in Failure(:note_invalid, _e) | Failure(:note_thread_invalid, _e)
      render_error _e, status: :unprocessable_entity
    end
  end

  def destroy
    event_id =
      Event.where(eventable_type: "Note", eventable_id: params[:id], type: "note_added").last.id
    case Notes::Destroy.new(
      id: params[:id],
      actor_account: current_account
    ).call
    in Success(note_thread)
      # Here note_thread instance is passed, but the record in the database may
      # be missing if the deleted note was the only one in note_thread.
      ActiveRecord::Associations::Preloader.new(
        records: [note_thread],
        associations: [:members, { notes: %i[member reacted_members] }]
      ).call

      notes_stream = build_turbo_stream_notes(note_thread:, action: :destroy)
      if note_thread.notable_type == "Task"
        since = params[:render_time].to_datetime
        remove_stream = remove_turbo_stream_activity(event_id)
        latest_activities_stream = add_turbo_stream_latest_activities(note_thread:, since:)
      end

      render_turbo_stream([notes_stream, remove_stream, latest_activities_stream])
    in Failure(:note_invalid, _e) | Failure(:note_thread_invalid, _e)
      render_error _e
    end
  end

  def show_edit_view
    render_time = params[:render_time].to_datetime
    render(partial: "shared/notes/note_edit", locals: { note: @note, render_time: })
  end

  def show_show_view
    thread = @note.note_thread

    render(
      partial: "shared/notes/note_show",
      locals: {
        note: @note,
        thread:,
        all_active_members: @all_active_members,
        hide_visibility_controls: thread.notable.is_a?(Task)
      }
    )
  end

  def add_reaction
    current_member.reacted_notes << @note unless current_member.reacted_to_note?(@note)
    reacted_names = @note.reacted_member_names(current_member)

    respond_to do |format|
      format.turbo_stream do
        render(
          turbo_stream: turbo_stream.replace(
            "note_reaction_#{@note.id}",
            partial: "shared/notes/note_reaction",
            locals: { note: @note, reacted_names:, member_react: true }
          )
        )
      end
      format.html { redirect_back(fallback_location: @note.url) }
    end
  end

  def remove_reaction
    current_member.reacted_notes.delete(@note) if current_member.reacted_to_note?(@note)
    reacted_names = @note.reacted_member_names(current_member)

    render(
      turbo_stream: turbo_stream.replace(
        "note_reaction_#{@note.id}",
        partial: "shared/notes/note_reaction",
        locals: { note: @note, reacted_names:, member_react: false }
      )
    )
  end

  private

  def note_params
    return unless params[:note]

    params.require(:note).permit(
      :text,
      note_thread: %i[
        id
        candidate_id
        position_id
        task_id
      ]
    )
  end

  def note_update_params
    params.require(:note).permit(:text)
  end

  def set_note
    @note = Note.find(params[:id])
  end

  def set_all_active_members
    @all_active_members =
      Member
      .joins(:account)
      .where.not(id: current_member.id)
      .order("accounts.name")
      .to_a
  end

  def render_mentioned_in_hidden_thread_modal(action:, forbidden_member_ids:)
    modal_params = mentioned_in_hidden_thread_modal_params(
      action:,
      forbidden_member_ids:
    )
    render_turbo_stream(turbo_stream.replace("turbo_modal_window", **modal_params))
  end

  def mentioned_in_hidden_thread_modal_params(action:, forbidden_member_ids:)
    forbidden_member_names = Member.where(id: forbidden_member_ids).pluck(:name)
    partial_name = "shared/notes/mentioned_in_hidden_thread_modal"
    modal_id = "mentioned-in-hidden-thread-modal"
    hidden_fields = {
      "mentioned_in_hidden_thread_modal" => "1",
      "note[text]" => note_params[:text],
      "forbidden_member_ids[]" => forbidden_member_ids.uniq
    }

    case action
    when :reply
      hidden_fields["note[note_thread][id]"] = note_params[:note_thread][:id]
      form_url = reply_notes_path
    when :update
      form_url = note_path(params[:id])
    end

    {
      partial: partial_name,
      layout: "layouts/modal",
      locals: {
        modal_id:,
        member_names: forbidden_member_names,
        form_options: {
          url: form_url,
          method: (action == :update ? :patch : :post)
        },
        hidden_fields:
      }
    }
  end

  def build_turbo_stream_notes(note_thread:, action:, expanded: false)
    dom_id =
      if action == :create
        "note-threads-#{note_thread.notable_id}"
      else
        ActionView::RecordIdentifier.dom_id(note_thread)
      end

    partial = "shared/note_threads/note_thread"
    locals = {
      note_thread:,
      all_active_members: @all_active_members,
      expanded:,
      hide_visibility_controls: note_thread.notable.is_a?(Task)
    }

    if action == :create
      turbo_stream.prepend(dom_id, partial:, locals:)
    elsif action.in?(%i[reply update destroy]) && note_thread.notes.present?
      turbo_stream.replace(dom_id, partial:, locals:)
    elsif action == :destroy && note_thread.notes.blank?
      turbo_stream.remove(dom_id)
    else
      raise NotImplementedError, "Unsupported action"
    end
  end

  def update_turbo_stream_activity(event_id)
    turbo_stream.replace(
      "event-#{event_id}",
      partial: "ats/tasks/activity_event_row",
      collection: Event.where(id: event_id),
      as: :event
    )
  end

  def remove_turbo_stream_activity(event_id)
    turbo_stream.remove("event-#{event_id}")
  end

  def add_turbo_stream_latest_activities(note_thread:, since:)
    task = note_thread.notable
    turbo_stream.prepend(
      "turbo_task_event_list",
      partial: "ats/tasks/activity_event_row",
      collection: task.activities(since:),
      as: :event
    )
  end
end
