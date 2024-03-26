# frozen_string_literal: true

Rails.application.routes.draw do
  # TODO: change root path
  root to: "ats/candidates#index"

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
      delete :remove_avatar, on: :member
      post :upload_file, on: :member
      delete :delete_file, on: :member
      patch :change_cv_status, on: :member
      get ":tab", to: "candidates#show", on: :member,
                  tab: /info|emails|scorecards|files|activities/, as: "tab"
    end
  end

  namespace :api, defaults: { format: "json" } do
    namespace :v1 do
      resource :locations, only: [] do
        get :fetch_locations
      end
    end
  end

  # TODO: check that admin interface is protected by authentication.
  mount RailsAdmin::Engine => "/admin", as: "rails_admin"

  # TODO: add authentication before accessing the lookbook.
  mount Lookbook::Engine, at: "lookbook" unless Rails.env.test?

  # TODO: add authentication before accessing the pghero.
  mount PgHero::Engine, at: "pghero"

  # TODO: add authentication before accessing the blazer.
  mount Blazer::Engine, at: "blazer"

  # TODO: add authentication before accessing jobs.
  mount MissionControl::Jobs::Engine, at: "jobs"
end
