# frozen_string_literal: true

class ATS::ProfilePolicy < ApplicationPolicy
  # Not all users will want to link their email accounts,
  # so for now we have decided to hide this functionality.
  def link_gmail?
    member.tenant.name == "Toughbyte" # TODO: change to false
  end
end
