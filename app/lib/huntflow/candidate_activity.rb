# frozen_string_literal: true

class Huntflow::CandidateActivity
  attr_reader :id, :type, :position_id, :status, :source, :rejection_reason,
              :created, :employment_date, :account_info, :comment, :files, :email,
              :survey_questionary, :survey_answer_of_type_a, :calendar_event, :hired_in_fill_quota

  def initialize(params)
    @id = params[:id]
    @type = params[:type]
    @position_id = params[:vacancy]
    @status = params[:status]
    @source = params[:source]
    @rejection_reason = params[:rejection_reason]
    @created = params[:created]
    @employment_date = params[:employment_date]
    @account_info = params[:account_info]
    @comment = params[:comment]
    @files = params[:files]
    @calendar_event = params[:calendar_event]
    @hired_in_fill_quota = params[:hired_in_fill_quota]
    @applicant_offer = params[:applicant_offer]
    @email = params[:email]
    @survey_questionary = params[:survey_questionary]
    @survey_answer_of_type_a = params[:survey_answer_of_type_a]
  end
end
