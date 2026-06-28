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
  devise_scope :admin_user do
    get  'admin_users/otp',        to: 'login/admin_users/sessions#otp_challenge', as: :admin_user_otp_challenge
    post 'admin_users/otp/verify', to: 'login/admin_users/sessions#verify_otp',    as: :verify_admin_user_otp
    post 'admin_users/otp/resend', to: 'login/admin_users/sessions#resend_otp',    as: :resend_admin_user_otp
  end

  devise_for :users, controllers: {
    sessions: 'login/users/sessions',
    passwords: 'login/users/passwords',
    confirmations: 'login/users/confirmations',
    unlocks: 'login/users/unlocks',
    registrations: 'login/users/registrations'
  }
  devise_scope :user do
    get  'users/otp',        to: 'login/users/sessions#otp_challenge', as: :user_otp_challenge
    post 'users/otp/verify', to: 'login/users/sessions#verify_otp',    as: :verify_user_otp
    post 'users/otp/resend', to: 'login/users/sessions#resend_otp',    as: :resend_user_otp
  end

  authenticate :admin_user do
    mount Sidekiq::Web => '/sidekiq'

    namespace :admin_area, path: 'admin', as: :admin do
      get 'my_account' => 'my_account#show'
      put 'my_account' => 'my_account#update'
      delete 'my_account' => 'my_account#destroy'

      resources :sessions, only: [:destroy] do
        collection do
          delete '', to: 'sessions#destroy_all', as: :destroy_all
        end
      end

      resource :two_factors, only: [:update]

      get 'dashboard', to: 'dashboard#show'
    end
  end

  authenticate :user do
    namespace :user_area, path: 'user', as: :user do
      get 'my_account' => 'my_account#show'
      put 'my_account' => 'my_account#update'
      delete 'my_account' => 'my_account#destroy'

      resources :sessions, only: [:destroy] do
        collection do
          delete '', to: 'sessions#destroy_all', as: :destroy_all
        end
      end

      resource :two_factors, only: [:update]

      get 'company_setup/new' => 'company_setup#new'
      post 'company_setup' => 'company_setup#create'

      scope path: 'companies/:company_id' do
        get 'company_setup/edit' => 'company_setup#edit'
        put 'company_setup' => 'company_setup#update'
        delete 'company_setup' => 'company_setup#destroy'

        resources :company_users, only: [:index, :update, :destroy]

        resources :invitations, only: [:index, :create, :destroy]
        put 'invitations/:id/resend', to: 'invitations#resend'

        resources :sites, only: [:index, :show, :create, :update, :destroy]
      end

      scope path: 'sites/:site_id' do
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
        post 'programs/modbus_device/:id/refresh', to: 'programs#refresh_modbus_device', as: :modbus_device_programs_refresh
      end

      get 'dashboard', to: 'dashboard#show'
    end
  end

  namespace :api do
    namespace :v1 do
      namespace :hooks do
        post 'gateway_status', to: 'gateway_status#update'
      end

      resources :plc_data, only: [:create]
    end

    namespace :mobile do
      namespace :v1 do
        post   'sign_in', to: 'sessions#create'
        delete 'sign_out', to: 'sessions#destroy_current'
        resources :sessions, only: [:index, :destroy]

        post 'otp/verify', to: 'otp#verify'
        post 'otp/resend', to: 'otp#resend'

        get 'me', to: 'me#show'

        scope path: 'sites/:site_id' do
          get 'live', to: 'live#show'
          get 'live/poll', to: 'live#poll'
          get 'live/poll_weather', to: 'live#poll_weather'

          resources :measurement_points, only: [:update] do
            member do
              post :write
              get :operation_mode_config
            end
            collection do
              post :bulk_write
            end
          end

          resources :alerts, only: [:index, :show]
        end
      end
    end
  end

  match '/home', to: 'static_pages#home', via: 'get'
  match '/privacy_policy', to: 'static_pages#privacy_policy', via: 'get'

  get 'invitations/:token/accept', to: 'invitations#accept', as: :accept_invitation
  put 'invitations/:token/accept', to: 'invitations#sign_up_and_accept'

  namespace :api do
    get 'regions/:country', to: 'regions#index'
    get 'cities/:country', to: 'regions#cities'
  end
end
