# frozen_string_literal: true

class ATS::CandidatesController < ApplicationController
  include Dry::Monads[:result]
  # TODO: add authorization

  layout "ats/application"

  TABS = %w[Info Emails Scorecards Files Activities].freeze
  INFO_CARDS =
    {
      contact_info: %w[source emails phones links telegram skype],
      cover_letter: %w[cover_letter]
    }.freeze
  private_constant :INFO_CARDS

  before_action :set_candidate, only: %i[show show_header edit_header update_header
                                         show_card edit_card update_card remove_avatar
                                         upload_file change_cv_status delete_file
                                         delete_cv_file download_cv_file upload_cv_file]

  def index
    @candidates_grid = ATS::CandidatesGrid.new(
      helpers.add_default_sorting(
        params.fetch(:ats_candidates_grid, {})
        .merge(page: params[:page]),
        :added
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
        when "emails"
          # emails
        when "scorecards"
          # scorecards
        when "files"
          @all_files = @candidate.all_files
        when "activities"
          # activities
          # else
          # something is wrong
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
    case Candidates::Add.new(params: candidate_params.to_h).call
    in Success(candidate)
      redirect_to tab_ats_candidate_path(candidate, :info),
                  notice: "Candidate was successfully created."
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
    @candidate.change(candidate_params)
    render_turbo_stream(
      [
        turbo_stream.replace(
          :turbo_header_section,
          partial: "ats/candidates/header_show"
        )
      ]
    )
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

    @candidate.change(candidate_params)
    card_name = params[:card_name]

    if card_name == "contact_info" && !helpers.candidate_card_contact_info_has_data?(@candidate) ||
       card_name == "cover_letter" && @candidate.cover_letter.blank?
      render_turbo_stream(
        [
          turbo_stream.replace(
            "turbo_#{card_name}_section",
            partial: "shared/profile/card_empty",
            locals: { card_name:, target_model: @candidate }
          )
        ]
      )
    else
      render_turbo_stream(
        [
          turbo_stream.replace(
            "turbo_#{card_name}_section",
            partial: "ats/candidates/info_cards/#{card_name}_show",
            locals: { candidate: @candidate }
          )
        ]
      )
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
    @candidate.files.attach(candidate_params[:file])

    redirect_to tab_ats_candidate_path(@candidate, :files)
  end

  def upload_cv_file
    file = @candidate.files.attach(candidate_params[:file]).attachments.last
    file.change_cv_status(true)

    redirect_to tab_ats_candidate_path(@candidate, :info)
  end

  def delete_file
    @candidate.destroy_file(candidate_params[:file_id_to_remove])

    render_candidate_files(@candidate)
  end

  def delete_cv_file
    @candidate.destroy_file(candidate_params[:file_id_to_remove])

    redirect_to tab_ats_candidate_path(@candidate, :info)
  end

  def change_cv_status
    file = @candidate.files.find(candidate_params[:file_id_to_change_cv_status])

    file.change_cv_status(candidate_params[:new_cv_status])
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
        :new_cv_status,
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
        candidate_email_addresses_attributes: %i[address status url source type]
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

    @candidate_params
  end

  # rubocop:disable Naming/MemoizedInstanceVariableName
  def set_layout_variables
    @tabs = TABS.index_by(&:downcase)
    @active_tab ||=
      if @tabs.key?(params[:tab])
        params[:tab]
      else
        @tabs.keys.first
      end
  end
  # rubocop:enable Naming/MemoizedInstanceVariableName

  def set_header_variables
    @created_at = @candidate.created_at
    # @created_at = @candidate.events.find_by(type: :candidate_added)&.performed_at ||
    #               @candidate.created_at
    # @all_internal_recruiter_names = Member.employee.order("users.name").pluck("users.name")
  end

  def set_candidate
    @candidate = Candidate.find(params[:candidate_id] || params[:id])

    return if @candidate.merged_to.nil?

    redirect_to tab_ats_candidate_path(@candidate.merged_to, params[:tab] || :info) # ,
    # warning: MERGED_WARNING
  end

  def render_candidate_files(candidate)
    render_turbo_stream(
      turbo_stream.update(
        "turbo_candidate_files", partial: "ats/candidates/candidate_files",
                                 locals: { all_files: candidate.all_files, candidate: }
      )
    )
  end
end
