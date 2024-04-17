# frozen_string_literal: true

Rails.application.routes.draw do
  root to: "ats/dashboard#index"

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :ats do
    resource :lookbook, only: [], controller: "lookbook" do
      get :fetch_options_for_select_component_preview
    end

    resources :candidates, except: %i[show edit] do
      get "/", to: redirect("/ats/candidates/%{id}/info"), on: :member, id: /\d+/
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
      get ":tab", to: "candidates#show", on: :member,
                  tab: /info|emails|scorecards|files|activities/, as: "tab"

      resources :placements, only: %i[create destroy], shallow: true do
        post :change_stage, on: :member
        post :change_status, on: :member
      end
    end

    resources :positions, except: %i[edit update] do
      get "/", to: redirect("/ats/positions/%{id}/info"), on: :member, id: /\d+/
      get ":tab",
          to: "positions#show",
          on: :member,
          tab: /info|pipeline||sequence_templates||activities/,
          as: "tab"
      patch :change_status, on: :member
      patch :reassign_recruiter, on: :member
      get :show_header, on: :member
      get :edit_header, on: :member
      patch :update_header, on: :member
      patch :update_side_header, to: "positions#update_side_header", on: :member
      get :show_card, on: :member
      get :edit_card, on: :member
      patch :update_card, to: "positions#update_card", on: :member
      get :fetch_pipeline_placements, to: "placements#fetch_pipeline_placements"
    end

    resources :scorecard_templates, only: %i[new create show edit update]
    resources :scorecards, only: %i[new create show edit update]
  end

  namespace :api, defaults: { format: "json" } do
    namespace :v1 do
      resource :locations, only: [] do
        get :fetch_locations
      end

      resource :members, only: [] do
        get :fetch_members
      end

      resource :positions, only: [] do
        get :fetch_positions
      end

      resource :candidate_sources, only: [] do
        get :fetch_candidate_sources
      end
    end
  end

  resources :notes, only: %i[create update destroy] do
    post :add_reaction, on: :member
    post :remove_reaction, on: :member
    get :show_edit_view, on: :member
    get :show_show_view, on: :member
    post :reply, on: :collection
  end

  resources :note_threads, only: :update do
    get :change_visibility_modal, on: :member
  end

  # rubocop:disable Style/SymbolProc
  constraints(Rodauth::Rails.authenticate { |rodauth| rodauth.admin? }) do
    mount RailsAdmin::Engine => "admin", as: "rails_admin"

    mount Lookbook::Engine, at: "lookbook" unless Rails.env.test?

    mount PgHero::Engine, at: "pghero"

    mount MissionControl::Jobs::Engine, at: "jobs"
  end

  constraints(Rodauth::Rails.authenticate { |rodauth| rodauth.admin? || rodauth.employee? }) do
    mount Blazer::Engine, at: "stats"
  end
  # rubocop:enable Style/SymbolProc
end
