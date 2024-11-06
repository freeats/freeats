# frozen_string_literal: true

RailsAdmin.config do |config|
  config.asset_source = :sprockets

  config.parent_controller = "DevopsAuthenticationController"

  ### Popular gems integration

  ## == Devise ==
  # config.authenticate_with do
  #   warden.authenticate! scope: :user
  # end
  # config.current_user_method(&:current_user)

  ## == CancanCan ==
  # config.authorize_with :cancancan

  ## == Pundit ==
  # config.authorize_with :pundit

  ## == PaperTrail ==
  # config.audit_with :paper_trail, 'User', 'PaperTrail::Version' # PaperTrail >= 3.0.0

  ### More at https://github.com/railsadminteam/rails_admin/wiki/Base-configuration

  ## == Gravatar integration ==
  ## To disable Gravatar integration in Navigation Bar set to false
  # config.show_gravatar = true

  config.actions do
    dashboard                     # mandatory
    index                         # mandatory
    new
    export
    bulk_delete
    show
    edit
    delete
    show_in_app

    ## With an audit adapter, you can add:
    # history_index
    # history_show
  end

  # Implement `rails_admin_name` method in models to have a pretty name for them.
  config.label_methods.unshift(:rails_admin_name)

  config.model("Account") do
    include_fields :id, :name, :email, :member, :avatar, :linkedin_url, :calendar_url,
                   :female, :tenant

    edit do
      exclude_fields :member
    end

    configure :status do
      enum do
        { unverified: 1, verified: 2, closed: 3 }
      end
    end
  end

  config.model("Member") do
    list do
      include_fields :id, :account, :access_level, :created_at, :tenant
      search_by :rails_admin_search
    end

    show_edit_fieilds = %i[id account access_level updated_at created_at
                           collaborator_positions positions tenant]
    show do
      include_fields(*show_edit_fieilds)
    end
    edit do
      include_fields(*show_edit_fieilds)

      configure :access_level do
        enum do
          %i[interviewer hiring_manager member admin].index_with(&:to_s)
        end
      end

      configure(:account) { required true }
    end
  end

  config.model("Event") do
    include_fields :id, :type, :performed_at, :actor_account, :eventable,
                   :changed_field, :properties
    # Without explicit configuration rails admin don't show these fields.
    field :changed_to, :jsonb
    field :changed_from, :jsonb
  end

  config.model("Position") do
    exclude_fields :slug
  end
end
