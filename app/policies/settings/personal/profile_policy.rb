# frozen_string_literal: true

class Settings::Personal::ProfilePolicy < ApplicationPolicy
  # Not all users will want to link their email accounts,
  # so for now we have decided to hide this functionality.
  def link_gmail?
    false
  end
end
