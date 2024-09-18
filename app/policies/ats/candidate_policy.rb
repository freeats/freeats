# frozen_string_literal: true

class ATS::CandidatePolicy < ApplicationPolicy
  alias_rule :destroy?, to: :available_for_admin?

  # Not all users will want to link their email accounts,
  # so for now we have decided to hide this functionality.
  def show_emails?
    false
  end
end
