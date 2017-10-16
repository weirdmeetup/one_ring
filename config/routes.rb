Rails.application.routes.draw do
  root "channels#index"
  resources :channels
end
