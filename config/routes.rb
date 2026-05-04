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

      resources :sessions, only: [:index, :destroy] do
        collection do
          delete '', to: 'sessions#destroy_all', as: :destroy_all
        end
      end

      get 'dashboard', to: 'dashboard#show'
    end
  end

  authenticate :user do
    namespace :user_area, path: 'user', as: :user do
      root 'live#show'

      get 'my_account' => 'my_account#show'
      put 'my_account' => 'my_account#update'
      delete 'my_account' => 'my_account#destroy'

      resources :sessions, only: [:index, :destroy] do
        collection do
          delete '', to: 'sessions#destroy_all', as: :destroy_all
        end
      end

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
      resources :devices, only: [:index]
      resources :gateways, only: [:update]
      resources :plcs, only: [:show, :update] do
        member do
          post :refresh_interfaces
        end
      end
      resources :modbus_devices, only: [:show, :create, :update, :destroy] do
        member do
          post :refresh_values
        end
      end
      resources :measurement_points, only: [:update] do
        collection do
          post :bulk_write
        end
        member do
          post :write
          get :operation_mode_config
        end
      end

      resources :alerts, only: [:index, :show]
      resources :alert_rules, except: [:show]
      resources :alert_subscriptions, path: 'notification_settings', only: [:index, :create, :update, :destroy]

      get 'live' => 'live#show'
      get 'live/poll' => 'live#poll'
      get 'live/poll_weather' => 'live#poll_weather'

      get 'analytics' => 'analytics#show'
      get 'analytics/hourly' => 'analytics#hourly'
      get 'analytics/raw' => 'analytics#raw'
      get 'analytics/weather_hourly' => 'analytics#weather_hourly'
      get 'analytics/weather_raw' => 'analytics#weather_raw'

      get 'programs', to: 'programs#index'
      get 'programs/plc/:id', to: 'programs#show_plc', as: :plc_programs
      get 'programs/modbus_device/:id', to: 'programs#show_modbus_device', as: :modbus_device_programs

      get 'dashboard', to: 'dashboard#show'
    end
  end

  namespace :api do
    namespace :v1 do
      resources :plc_data, only: [:create]
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
