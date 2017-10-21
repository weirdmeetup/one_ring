Rails.application.routes.draw do
  root "channels#index"
  resources :channels, except: [:edit, :update]
end
