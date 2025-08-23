require 'sidekiq/web'
require 'sidekiq-scheduler/web'

Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  root 'static_pages#home'

  devise_for :admin_users, controllers: {
    sessions: 'login/admin_users/sessions',
    passwords: 'login/admin_users/passwords',
    confirmations: 'login/admin_users/confirmations',
    unlocks: 'login/admin_users/unlocks'
  }
  devise_for :users, controllers: {
    sessions: 'login/users/sessions',
    passwords: 'login/users/passwords',
    confirmations: 'login/users/confirmations',
    unlocks: 'login/users/unlocks',
    registrations: 'login/users/registrations'
  }

  authenticate :admin_user do
    mount Sidekiq::Web => '/sidekiq'

    namespace :admin_area, path: 'admin', as: :admin do
      root 'dashboard#index'

      get 'dashboard', to: 'dashboard#index'
    end
  end

  authenticate :user do
    namespace :user_area, path: 'user', as: :user do
      root 'dashboard#index'

      get 'client_setup/new' => 'client_setup#new'
      get 'client_setup/edit' => 'client_setup#edit'
      post 'client_setup' => 'client_setup#create'
      put 'client_setup' => 'client_setup#update'
      delete 'client_setup' => 'client_setup#destroy'

      get 'client_setup', to: 'client_setup#new'
      post 'client_setup', to: 'client_setup#create'

      get 'users', to: 'users#index'

      get 'roles', to: 'roles#index'

      resources :invitations, only: [:index, :create, :destroy]
      put 'invitations/:id/resend', to: 'invitations#resend'
      get 'invitations/:token/accept', to: 'invitations#accept'

      get 'dashboard', to: 'dashboard#index'
    end
  end

  match '/home',                        to: 'static_pages#home',               via: 'get'
  match '/privacy_policy',              to: 'static_pages#privacy_policy',     via: 'get'

  resources :plc_manufacturers
  resources :plc_models
  resources :plcs

  namespace :api do
    get 'regions/:country', to: 'regions#index'
    get 'cities/:country', to: 'regions#cities'
  end
end
