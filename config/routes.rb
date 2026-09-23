Rails.application.routes.draw do
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
      get "profile", to: "users#show"
      patch "profile", to: "users#update"

      resources :courts, only: %i[index show]

      get "me/matches", to: "matches#mine"

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
end
