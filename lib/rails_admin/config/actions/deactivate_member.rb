# frozen_string_literal: true

require "rails_admin/config/actions"
require "rails_admin/config/actions/base"

class RailsAdmin::Config::Actions::DeactivateMember < RailsAdmin::Config::Actions::Base
  register_instance_option :visible? do
    authorized? && bindings[:object].is_a?(Member) && bindings[:object].active?
  end
  register_instance_option :member do
    true
  end
  register_instance_option :link_icon do
    "fas fa-circle-xmark"
  end
  register_instance_option :pjax? do
    false
  end
  register_instance_option :controller do
    proc do
      if @object.deactivate
        flash[:notice] = "Member #{@object.account.email} deactivated"
      else
        flash[:alert] =
          sanitize("Couldn't deactivate member #{@object.account.email}. " \
                   "#{@object.errors.full_messages.to_sentence}")
      end
      redirect_to back_or_index
    end
  end
end
