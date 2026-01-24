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
      root 'dashboard#show'

      get 'dashboard', to: 'dashboard#show'
    end
  end

  authenticate :user do
    namespace :user_area, path: 'user', as: :user do
      root 'dashboard#show'

      get 'my_account' => 'my_account#show'
      put 'my_account' => 'my_account#update'
      delete 'my_account' => 'my_account#destroy'

      get 'company_setup/new' => 'company_setup#new'
      get 'company_setup/edit' => 'company_setup#edit'
      post 'company_setup' => 'company_setup#create'
      put 'company_setup' => 'company_setup#update'
      delete 'company_setup' => 'company_setup#destroy'

      get 'company_setup', to: 'company_setup#new'
      post 'company_setup', to: 'company_setup#create'

      resources :company_users, only: [:index, :update, :destroy]

      # resources :invitations, only: [:index, :create, :update, :destroy]
      resources :invitations, only: [:index, :create, :destroy]
      put 'invitations/:id/resend', to: 'invitations#resend'

      resources :sites, only: [:index, :show, :create, :update, :destroy]
      resources :terminals, only: [:index, :update, :destroy]
      resources :plcs, only: [:show, :update]
      resources :measurement_points, only: [:update] do
        member do
          post :write
        end
      end

      get 'dashboard', to: 'dashboard#show'
    end
  end

  match '/home',                        to: 'static_pages#home',               via: 'get'
  match '/privacy_policy',              to: 'static_pages#privacy_policy',     via: 'get'

  get 'invitations/:token/accept', to: 'invitations#accept', as: :accept_invitation
  put 'invitations/:token/accept', to: 'invitations#sign_up_and_accept'

  namespace :api do
    get 'regions/:country', to: 'regions#index'
    get 'cities/:country', to: 'regions#cities'
  end
end
