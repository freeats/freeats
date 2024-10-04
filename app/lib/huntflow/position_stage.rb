# frozen_string_literal: true

class Huntflow::PositionStage
  attr_reader :id, :name, :order, :removed, :job, :type

  BACKLOG_ID = 155_798
  DISQUALIFY_ID = 155_797

  REJECTION_REASONS_MATCHING = {
    108_638 => "not_interested", # Candidate's refusal
    108_644 => "other_offer", # Choose another company
    108_642 => "team_fit", # Culture fit mismatch
    108_645 => "underqualified", # Industry background mismatch
    108_641 => "underqualified", # Lack of experience
    108_639 => "no_reply", # No response
    108_643 => "underqualified", # Rejected after a test case
    108_637 => "overpriced", # Salary expectation mismatch
    108_640 => "team_fit" # Soft skills/ Personality
    # null => "other"# По другой причине
  }.freeze

  def self.index
    Huntflow::API.get("accounts/#{Huntflow::API::ACCOUNT_ID}/vacancies/statuses")["items"]
                 .map { new(_1.deep_symbolize_keys) }
  end

  def initialize(params)
    @id = params[:id]
    @type = params[:type]
    @order = params[:order]
    @name = params[:name]
    @removed = params[:removed]
  end
end
