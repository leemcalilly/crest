Rails.application.routes.draw do
  root "home#show"

  resources :cycles, only: %i[ index show ], param: :slug
  resources :players, only: %i[ index show ], param: :slug
  resources :matches, only: %i[ index show ]

  resource :sources, only: :show

  get "up" => "rails/health#show", as: :rails_health_check
end
