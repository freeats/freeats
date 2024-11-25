# frozen_string_literal: true

class ATS::CandidatesController < AuthorizedController
  include Dry::Monads[:result]

  layout "ats/application"

  ACTIVITIES_PAGINATION_LIMIT = 25
  DEFAULT_TAB_PAGINATION_LIMIT = 10
  TABS = %w[Info Tasks Emails Scorecards Files Activities].freeze
  INFO_CARDS =
    {
      contact_info: %w[source emails phones links telegram skype],
      cover_letter: %w[cover_letter]
    }.freeze

  private_constant :INFO_CARDS

  before_action :set_gon_variables
  before_action { @nav_item = :candidates }
  before_action :set_candidate, only: %i[show show_header edit_header update_header
                                         show_card edit_card update_card remove_avatar
                                         upload_file change_cv_status delete_file
                                         delete_cv_file download_cv_file upload_cv_file
                                         assign_recruiter synchronize_email_messages
                                         merge_duplicates_modal merge_duplicates destroy
                                         fetch_positions]
  before_action :authorize!, only: %i[create new index]
  before_action -> { authorize!(@candidate) },
                only: %i[show show_header edit_header update_header
                         show_card edit_card update_card remove_avatar
                         upload_file change_cv_status delete_file
                         delete_cv_file download_cv_file upload_cv_file
                         assign_recruiter synchronize_email_messages destroy fetch_positions]

  def index
    @candidates_grid = ATS::CandidatesGrid.new(
      helpers.add_default_sorting(
        params.fetch(:ats_candidates_grid, {})
        .merge(page: params[:page]),
        :last_activity
      )
    ) do |scope|
      scope.page(params[:page])
    end

    @candidates_count = @candidates_grid.assets.unscope(:offset, :order, :limit).size
  end

  def show
    respond_to do |format|
      format.html do
        set_layout_variables

        case @active_tab
        when "info"
          # info
        when "tasks"
          @lazy_load_form_url =
            if params[:task_id]
              if params[:task_id] == "new"
                new_modal_ats_tasks_path(
                  params: { taskable_id: @candidate.id, taskable_type: @candidate.class.name }
                )
              else
                show_modal_ats_task_path(params[:task_id], grid: :profiles)
              end
            end
          @tasks_grid = ATS::ProfileTasksGrid.new(
            helpers.add_default_sorting(
              params[:ats_profile_tasks_grid],
              :due_date, :desc
            )
          )
          @tasks_grid.scope do |scope|
            scope.where(taskable: @candidate)
                 .page(params[:page])
                 .per(DEFAULT_TAB_PAGINATION_LIMIT)
          end
        when "emails"
          candidate_emails = @candidate.all_emails
          @hashed_avatars = {}
          @single_message = params[:email_message_id].present?
          @ordered_candidate_email_threads =
            if @single_message
              EmailMessage.with_addresses.where(id: params[:email_message_id])
            else
              result = BaseQueries.last_messages_of_each_thread(
                email_thread_ids:
                  EmailThread.get_threads_with_addresses(
                    email_address: candidate_emails
                  ).ids,
                includes: %i[events email_thread],
                per_page: DEFAULT_TAB_PAGINATION_LIMIT,
                page: params[:page]
              )
              Kaminari
                .paginate_array(result[:records], total_count: result[:total_count])
                .page(params[:page])
                .per(DEFAULT_TAB_PAGINATION_LIMIT)
            end
          @specified_mail_to = params[:mail_to]
          @mail_to_address = @candidate.all_emails(status: :current, type: :personal).first
        when "scorecards"
          # Do not use `includes` for position `stages`, it breaks their order by list_index.
          @placements_with_scorecard_templates =
            @candidate
            .placements
            .preload(
              position: { stages_including_deleted: :scorecard_template },
              scorecards: [:added_event, { interviewer: :account }]
            )
            .where(<<~SQL)
              EXISTS (
                SELECT 1 FROM scorecard_templates
                JOIN position_stages
                  AS scorecard_template_stage
                  ON scorecard_templates.position_stage_id = scorecard_template_stage.id
                JOIN position_stages
                  AS placement_stage
                  ON placements.position_stage_id = placement_stage.id
                WHERE scorecard_template_stage.list_index <= placement_stage.list_index
                AND scorecard_template_stage.position_id = placements.position_id
              )
              OR EXISTS (
                SELECT 1
                FROM scorecards
                JOIN position_stages
                  ON position_stages.id = scorecards.position_stage_id
                  AND position_stages.deleted = true
                WHERE scorecards.placement_id = placements.id
              )
            SQL
        when "files"
          @all_files = @candidate.all_files
        when "activities"
          @all_activities =
            @candidate
            .events
            .union(
              Event
              .where(eventable_type: "EmailMessage")
              .where(
                eventable_id: EmailMessageAddress
                .where(address: @candidate.all_emails)
                .select(:email_message_id)
              )
            )
            .union(
              Event
              .where(eventable_type: "Placement")
              .where(eventable_id: @candidate.placements.ids)
            )
            .union(
              Event
              .where(eventable_type: "Scorecard")
              .where(
                eventable_id:
                  @candidate.placements.extract_associated(:scorecards).flatten.pluck(:id)
              )
            )
            .union(
              Event
              .where(eventable_type: "Task")
              .where(eventable_id: @candidate.tasks.ids)
              .where(type: Event::TASK_TYPES_FOR_PROFILE_ACTIVITY_TAB)
            )
            .union(
              Event
              .joins(
                "JOIN notes ON events.eventable_id = notes.id AND events.eventable_type = 'Note' " \
                "JOIN note_threads ON note_threads.id = notes.note_thread_id " \
                "JOIN candidates ON note_threads.notable_id = candidates.id " \
                "AND note_threads.notable_type = 'Candidate'"
              ).where(note_threads: { id: NoteThread.visible_to(current_member).select(:id) })
              .where(candidates: { id: @candidate.id })
            )
            # @candidate.files is an ActiveStorage::Attached::Many class,
            # so it doesn't work without .to_a
            .union(Event.where(eventable: @candidate.files.to_a))
            .order(performed_at: :desc)

          if params[:event]
            redirect_to tab_ats_candidate_path(@candidate, :activities,
                                               page: page_of_activity(params[:event]),
                                               anchor: "event-#{params[:event]}")
            return
          end

          @all_activities =
            @all_activities
            .includes(
              :stage_to,
              eventable: [:position, { placement: :position }],
              actor_account: :member,
              assigned_member: :account,
              unassigned_member: :account
            )
            .page(params[:page])
            .per(ACTIVITIES_PAGINATION_LIMIT)
        end
        render "#{@active_tab}_tab", layout: "ats/profile"
      end
    end
  end

  def new
    partial_name = "new_candidate_modal"
    render(
      partial: partial_name,
      layout: "modal",
      locals: {
        modal_id: partial_name.dasherize,
        form_options: {
          url: ats_candidates_path,
          method: :post,
          data: {
            turbo_frame: "_top"
          }
        },
        hidden_fields: {
          position_id: params[:position_id]
        }
      }
    )
  end

  def create
    case Candidates::Add.new(
      params: candidate_params.to_h.deep_symbolize_keys,
      actor_account: current_account,
      method: "manual"
    ).call
    in Success(candidate)
      redirect_to tab_ats_candidate_path(candidate, :info),
                  notice: t("candidates.candidate_created")
    in Failure[:candidate_invalid, candidate]
      redirect_to ats_candidates_path, alert: candidate.errors.full_messages
    end
  end

  def show_header
    set_header_variables
    render partial: "header_show"
  end

  def edit_header
    render partial: "header_edit"
  end

  def update_header
    set_header_variables
    case Candidates::Change.new(
      candidate: @candidate,
      actor_account: current_account,
      params: candidate_params.to_h.deep_symbolize_keys
    ).call
    in Success(_)
      @candidate.reload
      render_turbo_stream(
        [
          turbo_stream.replace(
            :turbo_header_section,
            partial: "ats/candidates/header_show"
          )
        ]
      )
    in Failure[:candidate_invalid, _e] | # rubocop:disable Lint/UnderscorePrefixedVariableName
       Failure[:alternative_name_invalid, _e] |
       Failure[:alternative_name_not_unique, _e]
      render_error _e, status: :unprocessable_entity
    end
  end

  def show_card
    return unless params[:card_name].to_sym.in?(INFO_CARDS)

    card_name = params[:card_name]

    if card_name == "contact_info" && !helpers.candidate_card_contact_info_has_data?(@candidate) ||
       card_name == "cover_letter" && @candidate.cover_letter.blank?
      render(
        partial: "shared/profile/card_empty",
        locals: { card_name:, target_model: @candidate }
      )
    else
      render(
        partial: "ats/candidates/info_cards/#{card_name}_show",
        locals: { candidate: @candidate }
      )
    end
  end

  def edit_card
    return unless params[:card_name].to_sym.in?(INFO_CARDS)

    card_name = params[:card_name]

    render(
      partial: "ats/candidates/info_cards/#{card_name}_edit",
      locals: {
        candidate: @candidate
      }
    )
  end

  def update_card
    return unless params[:card_name].to_sym.in?(INFO_CARDS)

    card_name = params[:card_name]
    emails_changed = nil
    links_changed = nil
    phones_changed = nil

    if card_name == "contact_info"
      email_fields = %w[address status url source type]
      current_emails = @candidate.candidate_email_addresses.order("address ASC")
      new_emails = candidate_params[:emails].sort_by { _1["address"] }

      phone_fields = %w[phone status source type]
      current_phones = @candidate.candidate_phones&.sort_by { _1["phone"] }
      new_phones = candidate_params[:phones]&.sort_by { _1["phone"] }

      current_links = @candidate.candidate_links&.sort_by { _1["url"] }
      new_links = candidate_params[:links]&.sort_by { _1["url"] }

      if new_emails.present? && current_emails.size == new_emails.size
        current_emails.each_with_index do |existing_address, idx|
          new_address = new_emails[idx]
          email_fields.each do |field|
            if (existing_address.public_send(field) || "") != (new_address[field] || "")
              emails_changed = true
              break
            end
          end
          break if emails_changed
        end
      else
        emails_changed =
          current_emails.pluck(:address) != (new_emails.pluck(:address) || [])
      end

      if new_phones.present? && current_phones.size == new_phones.size
        current_phones.each_with_index do |existing_phone, idx|
          new_phone = new_phones[idx]
          phone_fields.each do |field|
            if (existing_phone.public_send(field) || "") != (new_phone[field] || "")
              phones_changed = true
              break
            end
          end
          break if phones_changed
        end
      else
        phones_changed =
          current_phones.pluck(:phone) != (new_phones&.pluck(:phone) || [])
      end

      links_changed =
        current_links.pluck(:url, :status).sort != (new_links&.pluck(:url, :status)&.sort || [])
    end

    case Candidates::Change.new(
      candidate: @candidate,
      actor_account: current_account,
      params: candidate_params.to_h.deep_symbolize_keys
    ).call
    in Success(_)
      @candidate.reload
      turbo_dialogs = []
      turbo_dialogs << turbo_merge_dialog if emails_changed || links_changed || phones_changed

      render_turbo_stream(
        [
          *turbo_dialogs,
          turbo_update_card(card_name)
        ]
      )
    in Failure[:candidate_invalid, _e] | # rubocop:disable Lint/UnderscorePrefixedVariableName
       Failure[:alternative_name_invalid, _e] |
       Failure[:alternative_name_not_unique, _e]
      render_error _e, status: :unprocessable_entity
    end
  end

  def assign_recruiter
    case Candidates::Change.new(
      candidate: @candidate,
      actor_account: current_account,
      params: { recruiter_id: params[:candidate][:recruiter_id] }
    ).call
    in Success(_)
      @candidate.reload
      locals = {
        currently_assigned_account: @candidate.recruiter&.account,
        tooltip_title: t("core.recruiter"),
        target_model: @candidate,
        target_url: assign_recruiter_ats_candidate_path(@candidate),
        input_button_name: "candidate[recruiter_id]",
        unassignment_label: t("core.unassign_recruiter"),
        mobile: params[:mobile]
      }
      set_layout_variables
      # rubocop:disable Rails/SkipsModelValidations
      render_turbo_stream(
        [
          rendered_notes_panel,
          turbo_stream.update_all(
            ".turbo_candidate_reassign_recruiter_button",
            partial: "shared/profile/reassign_button",
            locals:
          )
        ]
      )
    # rubocop:enable Rails/SkipsModelValidations
    in Failure[:candidate_invalid, error]
      render_error error
    end
  end

  def remove_avatar
    @candidate.avatar.purge
    @candidate.save!
    redirect_back fallback_location: tab_ats_candidate_path(@candidate, :info)
  rescue StandardError => e
    redirect_back fallback_location: tab_ats_candidate_path(@candidate, :info), alert: e.message
  end

  def upload_file
    case Candidates::UploadFile.new(
      candidate: @candidate,
      actor_account: current_account,
      file: candidate_params[:file]
    ).call
    in Success()
      redirect_to tab_ats_candidate_path(@candidate, :files)
    in Failure[:file_invalid, e]
      render_error e, status: :unprocessable_entity
    end
  end

  def upload_cv_file
    case Candidates::UploadFile.new(
      candidate: @candidate,
      actor_account: current_account,
      file: candidate_params[:file],
      cv: true
    ).call
    in Success()
      redirect_to tab_ats_candidate_path(@candidate, :info)
    in Failure[:file_invalid, e]
      render_error e, status: :unprocessable_entity
    end
  end

  def delete_file
    file = @candidate.files.find(candidate_params[:file_id_to_remove])

    case Candidates::RemoveFile.new(
      candidate: @candidate,
      actor_account: current_account,
      file:
    ).call
    in Success()
      render_candidate_files(@candidate)
    in Failure[:file_invalid, e]
      render_error e, status: :unprocessable_entity
    end
  end

  def delete_cv_file
    file = @candidate.files.find(candidate_params[:file_id_to_remove])

    case Candidates::RemoveFile.new(
      candidate: @candidate,
      actor_account: current_account,
      file:
    ).call
    in Success()
      redirect_to tab_ats_candidate_path(@candidate, :info)
    in Failure[:file_invalid, e]
      render_error e, status: :unprocessable_entity
    end
  end

  def change_cv_status
    file = @candidate.files.find(candidate_params[:file_id_to_change_cv_status])

    file.change_cv_status(current_account)
    if @candidate.errors.present?
      render_error @candidate.errors.full_messages
      return
    end

    render_candidate_files(@candidate)
  end

  def download_cv_file
    send_data @candidate.cv.download,
              filename: "#{@candidate.full_name} - #{@candidate.cv.blob.filename}",
              disposition: :attachment
  end

  def synchronize_email_messages
    @candidate.synchronize_email_messages
    redirect_to tab_ats_candidate_path(@candidate.id, "emails"),
                notice: "Started synchronizing emails. Please check back in a few minutes."
  end

  def merge_duplicates_modal
    @duplicates = @candidate.not_merged_duplicates
    @duplicate_recruiters =
      Member
      .active
      .where(id: [@candidate, *@duplicates].map(&:recruiter_id))
      .order("accounts.name")
      .pluck("accounts.name", :id)

    render_turbo_stream(
      turbo_stream.update(
        "merge-candidates-modal",
        partial: "ats/candidates/merge_duplicates_modal"
      )
    )
  end

  def merge_duplicates
    result = Candidates::Merge.new(
      target: @candidate,
      actor_account_id: current_account.id,
      new_recruiter_id: params[:new_recruiter_id]
    ).call

    case result
    in Success(target:)
      @candidate = target
    in Failure(:no_duplicates)
      return redirect_to tab_ats_candidate_path(@candidate, :info),
                         alert: t("candidates.no_duplicates_available_for_merge")
    end

    redirect_to tab_ats_candidate_path(@candidate, :info)
  end

  def destroy
    if @candidate.remove
      redirect_to ats_candidates_path, notice: t("candidates.candidate_deleted")
      return
    end

    render_error @candidate.errors.full_messages
  end

  def fetch_positions
    query = params[:q]

    positions =
      Position
      .where.not(status: :closed)
      .search_by_name(query)
      .order(:status, :name)
      .limit(20)
      .to_a

    ordered_positions = Positions::Order.new(positions:, query:).call.value!

    partials = ordered_positions.map do |position|
      render_to_string(partial: "position_element", locals: { position: })
    end

    render partial: "ats/quick_search/options", locals: { dataset: ordered_positions, partials: }
  end

  private

  def candidate_params
    return @candidate_params if @candidate_params.present?

    @candidate_params =
      params
      .require(:candidate)
      .permit(
        :avatar,
        :remove_avatar,
        :file,
        :cover_letter,
        :file_id_to_remove,
        :file_id_to_change_cv_status,
        :recruiter_id,
        :location_id,
        :full_name,
        :company,
        :blacklisted,
        :headline,
        :telegram,
        :skype,
        :source,
        links: [],
        alternative_names: [],
        emails: [],
        phones: []
      )

    email_params =
      params[:candidate].permit(
        candidate_email_addresses_attributes: %i[address status url source type created_via]
      )[:candidate_email_addresses_attributes]

    if email_params
      @candidate_params[:emails] = email_params.values.filter { _1[:address].present? }
    end

    phone_params =
      params[:candidate].permit(
        candidate_phones_attributes: %i[phone status source type]
      )[:candidate_phones_attributes]

    @candidate_params[:phones] = phone_params.values.filter { _1[:phone].present? } if phone_params

    link_params =
      params[:candidate].permit(
        candidate_links_attributes: %i[url status]
      )[:candidate_links_attributes]

    @candidate_params[:links] = link_params.values.filter { _1[:url].present? } if link_params

    alternative_name_params =
      params[:candidate].permit(
        candidate_alternative_names_attributes: :name
      )[:candidate_alternative_names_attributes]

    if alternative_name_params
      @candidate_params[:alternative_names] =
        alternative_name_params.values.filter { _1[:name].present? }
    end

    @candidate_params
  end

  def set_layout_variables
    @tabs = TABS.index_by(&:downcase)
    @active_tab ||=
      if @tabs.key?(params[:tab])
        params[:tab]
      elsif params[:task_id]&.match?(/(new|\d+)$/)
        "tasks"
      else
        @tabs.keys.first
      end
    @assigned_recruiter = @candidate.recruiter
    @duplicates = @candidate.duplicates_for_merge_dialog
    @pending_tab_tasks_count = Task.where(taskable: @candidate).open.size
    @email_count =
      EmailMessage.where(
        email_thread_id:
          EmailThread.get_threads_with_addresses(email_address: @candidate.all_emails).select(:id)
      ).count
    @scorecards_count = @candidate.scorecards.count
    set_placements_variables
    set_header_variables
  end

  def set_header_variables
    @created_at = @candidate.added_event.performed_at
  end

  def set_candidate
    @candidate = Candidate.find(params[:candidate_id] || params[:id])

    return if @candidate.merged_to.nil?

    redirect_to tab_ats_candidate_path(@candidate.merged_to, params[:tab] || :info),
                warning: t("candidates.merged_warning")
  end

  def suggested_members_names_for(active_members)
    member_names = active_members.map(&:name)
    first_results = []

    if @assigned_recruiter && @assigned_recruiter != current_member
      first_results << member_names.delete(@assigned_recruiter.name)
    end

    # Users who already made a note to the candidate.
    @candidate
      .note_threads
      .visible_to(current_member)
      .includes(notes: :member)
      .flat_map(&:notes)
      .map { |note| note.member.name }
      .each { |name| first_results << member_names.delete(name) }

    first_results.compact + member_names
  end

  def render_candidate_files(candidate)
    render_turbo_stream(
      turbo_stream.update(
        "turbo_candidate_files", partial: "ats/candidates/candidate_files",
                                 locals: { all_files: candidate.all_files, candidate: }
      )
    )
  end

  def turbo_update_card(card_name)
    if card_name == "contact_info" && !helpers.candidate_card_contact_info_has_data?(@candidate) ||
       card_name == "cover_letter" && @candidate.cover_letter.blank?
      turbo_stream.replace(
        "turbo_#{card_name}_section",
        partial: "shared/profile/card_empty",
        locals: { card_name:, target_model: @candidate }
      )
    else
      turbo_stream.replace(
        "turbo_#{card_name}_section",
        partial: "ats/candidates/info_cards/#{card_name}_show",
        locals: { candidate: @candidate }
      )
    end
  end

  def turbo_merge_dialog
    duplicates = @candidate.duplicates_for_merge_dialog
    if duplicates.present?
      turbo_stream.update(
        "turbo_merge_dialog_section",
        partial: "ats/candidates/merge_duplicates",
        locals: {
          candidate: @candidate,
          duplicates:
        }
      )
    else
      turbo_stream.update(
        "turbo_merge_dialog_section",
        ""
      )
    end
  end

  def set_placements_variables
    all_placements =
      @candidate
      .placements
      .select("placements.*, events.performed_at AS added_at")
      .joins(:added_event)
      .includes(:position_stage, :position)

    # Sort by created_at is intentional.
    @irrelevant_placements = all_placements.filter(&:disqualified?).sort_by(&:added_at).reverse
    @relevant_placements = (all_placements - @irrelevant_placements).sort_by(&:added_at).reverse
    @positions_for_quick_assignment = @candidate.positions_for_quick_assignment(current_member.id)

    @all_active_members = Member.active.to_a
    @suggested_names = suggested_members_names_for(@all_active_members)
    @note_threads =
      NoteThread
      .includes(notes: %i[member reacted_members])
      .preload(:members)
      .where(notable: @candidate)
      .visible_to(current_member)
      .sort_by { _1.notes.first }
      .reverse
  end

  def page_of_activity(event_id)
    num_of_activity = @all_activities.index { |activity| activity.id == event_id.to_i }.to_i + 1
    (num_of_activity.to_f / ACTIVITIES_PAGINATION_LIMIT).ceil
  end

  def rendered_notes_panel
    partial = "ats/candidates/notes_panel"
    locals = {
      all_active_members: @all_active_members,
      suggested_names: @suggested_names,
      note_threads: @note_threads,
      additional_create_param_input:
        helpers.hidden_field_tag("note[note_thread][candidate_id]", @candidate.id),
      hide_visibility_controls: false
    }
    turbo_stream.replace("turbo_notes_panel", partial:, locals:)
  end
end
