Rails.application.routes.draw do
  devise_for :users

  root "home#index"

  namespace :admin do
    root to: "dashboard#index"

    resources :courts
    resources :users, only: %i[index show edit update]
    resources :matches, only: %i[index show edit update]
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
