Rails.application.routes.draw do
  mount Rswag::Ui::Engine => "/api-docs"
  mount Rswag::Api::Engine => "/api-docs"
  devise_for :users

  root "home#index"

  namespace :admin do
    root to: "dashboard#index"

    resources :clubs
    resources :courts do
      resources :time_slots, shallow: true
    end
    resources :users
    resources :matches, only: %i[index show edit update] do
      resources :match_players, only: %i[create destroy]
      resources :match_results, only: %i[edit update destroy]
      member do
        post :force_result
        post :mark_played
      end
    end
  end

  namespace :api do
    namespace :v1 do
      post "login", to: "sessions#create"
      post "oauth/google", to: "google_sessions#create"
      get "profile", to: "users#show"
      patch "profile", to: "users#update"

      resources :courts, only: %i[index show]

      get "addresses/autocomplete", to: "addresses#autocomplete"

      resources :clubs, only: %i[index show create update destroy] do
        member do
          get :schedule, controller: "club_schedules", action: :show
          get :availability, controller: "club_availability", action: :show
        end
        resources :courts, only: %i[index show create update destroy], controller: "club_courts" do
          resources :time_slots, only: %i[index create update destroy], controller: "club_court_time_slots" do
            post :bulk, on: :collection
            match :day_override, on: :collection, via: %i[put delete]
          end
        end
        resources :walk_in_bookings, only: %i[create destroy]
      end

      get "me/matches", to: "matches#mine"
      get "me/court_bookings", to: "court_bookings#index"
      post "court_bookings", to: "court_bookings#create"
      delete "court_bookings/:id", to: "court_bookings#destroy"

      resources :matches, only: %i[index show create] do
        member do
          post :join
          delete :leave
          post :played
        end
        resources :match_results, only: %i[index create destroy]
      end
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check

  match "/404", to: "errors#not_found", via: :all
  match "/422", to: "errors#unprocessable_entity", via: :all
  match "/500", to: "errors#internal_server_error", via: :all
end
