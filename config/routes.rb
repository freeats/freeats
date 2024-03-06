# frozen_string_literal: true

Rails.application.routes.draw do
  # TODO: check that admin interface is protected by authentication.
  mount RailsAdmin::Engine => "/admin", as: "rails_admin"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"

  # TODO: add authentication before accessing the lookbook.
  mount Lookbook::Engine, at: "lookbook" unless Rails.env.test?

  # TODO: add authentication before accessing the pghero.
  mount PgHero::Engine, at: "pghero"

  # TODO: add authentication before accessing the blazer.
  mount Blazer::Engine, at: "blazer"

  # TODO: add authentication before accessing jobs.
  mount MissionControl::Jobs::Engine, at: "jobs"
end
