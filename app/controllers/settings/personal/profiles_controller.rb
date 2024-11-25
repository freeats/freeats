# frozen_string_literal: true

class Settings::Personal::ProfilesController < AuthorizedController
  def show
    render plain: "Hres is your profile"
  end
end
