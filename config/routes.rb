# frozen_string_literal: true

Rails.application.routes.draw do
  root to: "ats/dashboard#index"

  match "/403", to: "application#render403", via: :all
  match "/404", to: "application#render404", via: :all
  match "/422", to: "application#render422", via: :all
  match "/500", to: "application#render500", via: :all

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  get "register-mockup" => "rodauth#register"
  get "verify-email-mockup" => "rodauth#verify_email"
  get "invitation" => "rodauth#invite"
  post "accept_invite" => "rodauth#accept_invite"

  namespace :ats do
    resources :candidates, except: %i[show edit] do
      get "/", to: redirect("/ats/candidates/%{id}/info"), on: :member, id: /\d+/
      get "tasks/:task_id", to: "candidates#show", on: :member, as: "task"
      get :show_card, on: :member
      get :edit_card, on: :member
      patch :update_card, on: :member
      get :show_header, on: :member
      get :edit_header, on: :member
      patch :update_header, on: :member
      patch :assign_recruiter, on: :member
      delete :remove_avatar, on: :member
      post :upload_file, on: :member
      post :upload_cv_file, on: :member
      delete :delete_file, on: :member
      delete :delete_cv_file, on: :member
      patch :change_cv_status, on: :member
      get :download_cv_file, on: :member
      post :synchronize_email_messages, on: :member
      get :merge_duplicates_modal, on: :member
      post :merge_duplicates, on: :member
      get ":tab", to: "candidates#show", on: :member,
                  tab: /info|tasks|emails|scorecards|files|activities/, as: "tab"
      get :fetch_positions

      resources :placements, only: %i[create destroy], shallow: true do
        post :change_stage, on: :member
        post :change_status, on: :member
      end
    end

    resources :position_stages, only: :destroy

    resources :positions, except: %i[edit update] do
      get "/", to: redirect("/ats/positions/%{id}/info"), on: :member, id: /\d+/
      get "tasks/:task_id", to: "positions#show", on: :member, as: "task"
      get ":tab",
          to: "positions#show",
          on: :member,
          tab: /info|pipeline|tasks|activities/,
          as: "tab"
      patch :change_status, on: :member
      get :show_header, on: :member
      get :edit_header, on: :member
      patch :update_header, on: :member
      patch :update_side_header, to: "positions#update_side_header", on: :member
      get :show_card, on: :member
      get :edit_card, on: :member
      patch :update_card, to: "positions#update_card", on: :member
      get :fetch_pipeline_placements, to: "placements#fetch_pipeline_placements"
    end

    resources :scorecard_templates, only: %i[new create show edit update destroy]
    resources :scorecards, only: %i[new create show edit update destroy]

    get "team", to: "members#index"

    resources :members, only: [] do
      member do
        patch :deactivate
        patch :reactivate
        patch :update_level_access
      end
      collection do
        post :invite
        get :invite_modal
      end
    end

    resource :settings, only: %i[show] do
      get :link_gmail, path: "link-gmail"
      patch :update_account
      patch :update_avatar
      delete :remove_avatar
    end

    resource :lookbook, only: [], controller: "lookbook" do
      get :fetch_options_for_select_component_preview
    end

    resources :email_threads, only: [] do
      get :fetch_messages, on: :member
    end

    resources :tasks, only: %i[index create update new show] do
      get :new_modal, on: :collection
      get :show_modal, on: :member
      patch :update_status, on: :member
      # Remove the below post paths after implementing turbo_modals for
      # the show task modal with get method.
      post :new_modal, on: :collection
      post :show_modal, on: :member
    end

    resources :quick_search, only: :index, controller: "quick_search"
  end

  namespace :api, defaults: { format: "json" } do
    namespace :v1 do
      resource :locations, only: [] do
        get :fetch_locations
      end

      post "candidates", to: "documents#create"
    end
  end

  namespace :public, path: "/" do
    post "recaptcha/verify", to: "recaptcha#verify", format: "json"
  end

  resources :notes, only: %i[create update destroy] do
    # Will be called from email messages since POST is not allowed there.
    get :add_reaction, on: :member
    # Will be called from ats
    post :add_reaction, on: :member
    post :remove_reaction, on: :member
    get :show_edit_view, on: :member
    get :show_show_view, on: :member
    post :reply, on: :collection
  end

  resources :note_threads, only: :update do
    get :change_visibility_modal, on: :member
  end

  # The below routes are using the basic authuentication.
  mount RailsAdmin::Engine => "admin", as: "rails_admin"
  mount PgHero::Engine, at: "pghero"
  mount MissionControl::Jobs::Engine, at: "jobs"

  mount Lookbook::Engine, at: "lookbook" unless Rails.env.test?

  constraints(Rodauth::Rails.authenticate { |rodauth| rodauth.admin? || rodauth.member? }) do
    mount Blazer::Engine, at: "stats"
  end

  get "sites/:tenant_slug", to: "career_site/positions#index", as: "career_site_positions"
  get "sites/:tenant_slug/positions/:id", to: "career_site/positions#show", as: "career_site_position"
  post "sites/:tenant_slug/positions/:position_id/apply", to: "career_site/positions#apply", as: "apply_career_site_position"
end
