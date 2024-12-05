# frozen_string_literal: true

require "rails_admin/config/actions"
require "rails_admin/config/actions/base"

class RailsAdmin::Config::Actions::DeleteAccount < RailsAdmin::Config::Actions::Base
  register_instance_option :visible? do
    authorized? && bindings[:object].is_a?(Account)
  end
  register_instance_option :member do
    true
  end
  register_instance_option :link_icon do
    "fa fa-times-circle"
  end
  register_instance_option :pjax? do
    false
  end
  register_instance_option :controller do
    proc do
      account_name = @object.name
      if @object.cascade_destroy
        flash[:notice] = "Account #{account_name} deleted"
      else
        flash[:alert] = sanitize("Couldn't delete account #{@object.name}. " \
                                 "#{@object.errors.full_messages.to_sentence}")
      end
      redirect_to back_or_index
    end
  end
end
