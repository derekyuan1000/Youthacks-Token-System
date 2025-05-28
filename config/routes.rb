Rails.application.routes.draw do
  resources :admins

  get "sessions/new"
  get "sessions/create"
  get "sessions/destroy"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
  get    'login',  to: 'sessions#new', as: 'login'
  post   'login',  to: 'sessions#create'
  delete 'logout', to: 'sessions#destroy', as: 'logout'
  get "dashboard", to: "admins#dashboard", as: "dashboard"
  post "/participants/:id/set_balance", to: "admins#set_balance", as: "set_balance"
  post "participants/bulk_earn", to: "admins#bulk_earn", as: "bulk_earn"
  post "/participants/:id/earn", to: "admins#earn", as: "earn"
  get "products", to: "home#products", as: "products"
  post "/participants/:id/buy", to: "admins#buy", as: "buy"
  post "/products/create", to: "admins#create_product", as: "create_product"
  post "/products/:id/edit", to: "admin#update_product", as: "update_product"
  delete "participants/:id", to: "admins#delete_participant", as: "participant_delete"
  post "participants/:id/check_in", to: "admins#check_in_participant", as: "participant_check_in"
  get "activity", to: "admins#activity", as: "activity"
  get 'products/refresh', to: 'products#refresh'

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "home#index"
end
