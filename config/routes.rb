Rails.application.routes.draw do
  devise_for :users

  root "home#index"

  namespace :admin do
    root to: "dashboard#index"

    resources :courts
    resources :users, only: %i[index show edit update]
    resources :matches, only: %i[index show edit update]
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
