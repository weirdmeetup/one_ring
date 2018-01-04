# frozen_string_literal: true

Rails.application.routes.draw do
  get "dashboard", to: "dashboard#index"

  root "channels#index"
  resources :channels, except: %i[edit update] do
    resource :unarchive, only: %i[new create], controller: "channels/unarchive"
  end

  get "sign_in", to: "session#new", as: "sign_in"
  delete "sign_out", to: "session#destroy", as: "sign_out"
  get "auth/:provider/callback", to: "session#create"
end
