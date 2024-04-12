# frozen_string_literal: true

class NotesController < ApplicationController
  include Dry::Monads[:result]

  before_action :set_all_active_members,
                only: %i[create reply update destroy show_show_view]

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

      render_turbo_stream([notes_stream])
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

      notes_stream = build_turbo_stream_notes(note_thread:, action: :reply)

      render_turbo_stream([notes_stream])
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
      render_turbo_stream([notes_stream])
    in Failure(:mentioned_in_hidden_thread, forbidden_member_ids)
      render_mentioned_in_hidden_thread_modal(action: :update, forbidden_member_ids:)
    in Failure(:note_invalid, _e) | Failure(:note_thread_invalid, _e)
      render_error _e, status: :unprocessable_entity
    end
  end

  def destroy
    case Notes::Destroy.new(
      id: params[:id],
      actor_account: current_account
    ).call
    in Success(note)
      note_thread =
        NoteThread
        .includes(:members, notes: %i[member reacted_members])
        .find(note.note_thread_id)

      notes_stream = build_turbo_stream_notes(note_thread:, action: :destroy)
      render_turbo_stream([notes_stream])
    in Failure(:note_invalid, _e) | Failure(:note_thread_invalid, _e)
      render_error _e
    end
  end

  def show_edit_view
    note = Note.find(params[:id])

    render_time = params[:render_time].to_datetime
    render(partial: "shared/notes/note_edit", locals: { note:, render_time: })
  end

  def show_show_view
    note = Note.find(params[:id])
    thread = note.note_thread

    render(
      partial: "shared/notes/note_show",
      locals: {
        note:,
        thread:,
        all_active_members: @all_active_members
      }
    )
  end

  def add_reaction
    note = Note.find(params[:id])
    current_member.reacted_notes << note unless current_member.reacted_to_note?(note)
    reacted_names = note.reacted_member_names(current_member)

    respond_to do |format|
      format.turbo_stream do
        render(
          turbo_stream: turbo_stream.replace(
            "note_reaction_#{note.id}",
            partial: "shared/notes/note_reaction",
            locals: { note:, reacted_names:, member_react: true }
          )
        )
      end
      format.html { redirect_back(fallback_location: note.url) }
    end
  end

  def remove_reaction
    note = Note.find(params[:id])
    current_member.reacted_notes.delete(note) if current_member.reacted_to_note?(note)
    reacted_names = note.reacted_member_names(current_member)

    render(
      turbo_stream: turbo_stream.replace(
        "note_reaction_#{note.id}",
        partial: "shared/notes/note_reaction",
        locals: { note:, reacted_names:, member_react: false }
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
      ]
    )
  end

  def note_update_params
    params.require(:note).permit(:text)
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
      expanded:
    }

    if action == :create
      turbo_stream.prepend(dom_id, partial:, locals:)
    elsif action.in?(%i[reply update destroy]) && note_thread.notes.present?
      turbo_stream.replace(dom_id, partial:, locals:)
    elsif action == :destroy && note_thread.notes.blank?
      turbo_stream.remove(dom_id)
    else
      raise "Unsupported action"
    end
  end
end
