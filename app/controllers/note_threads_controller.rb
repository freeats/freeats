# frozen_string_literal: true

class NoteThreadsController < AuthorizedController
  before_action :set_note_thread
  before_action :set_all_active_members, only: :update
  before_action -> { authorize!(@note_thread) }, only: %i[update]

  def update
    @note_thread.update_visibility_settings(thread_params, current_member:)

    ActiveRecord::Associations::Preloader.new(
      records: [@note_thread],
      associations: [:members, { notes: %i[member reacted_members] }]
    )

    render_turbo_stream(
      turbo_stream.replace(
        ActionView::RecordIdentifier.dom_id(@note_thread),
        partial: "shared/note_threads/note_thread",
        locals: { note_thread: @note_thread, all_active_members: @all_active_members }
      )
    )
  end

  def change_visibility_modal
    modal_render_options = {
      partial: "shared/note_threads/change_note_thread_visibility_modal",
      layout: "layouts/modal",
      locals: {
        modal_id: "change-note-thread-visibility-modal",
        thread: @note_thread,
        all_active_members: Member.find(params[:all_active_members]),
        form_options: {
          url: note_thread_path(@note_thread.id),
          method: :patch,
          data: { controller: "note-thread" }
        }
      }
    }
    render(**modal_render_options)
  end

  private

  def thread_params
    params.require(:note_thread).permit(:hidden, members: [])
  end

  def set_note_thread
    @note_thread = NoteThread.includes(notes: :member).find(params[:id])
  end

  def set_all_active_members
    @all_active_members =
      Member
      .joins(:account)
      .where.not(id: current_member.id)
      .order("accounts.name")
      .to_a
  end
end
