Rails.application.routes.draw do
  devise_for :users

  root "home#index"

  namespace :admin do
    root to: "dashboard#index"

    resources :clubs
    resources :courts
    resources :users
    resources :matches, only: %i[index show edit update] do
      resources :match_players, only: %i[create destroy]
    end
  end

  namespace :api do
    namespace :v1 do
      post "login", to: "sessions#create"
      get "profile", to: "users#show"
      patch "profile", to: "users#update"

      resources :courts, only: %i[index show]
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
