Rails.application.routes.draw do
	resources :admins

	get "sessions/new"
	get "sessions/create"
	get "sessions/destroy"

	# Health check endpoint
	get "up" => "rails/health#show", as: :rails_health_check

	get    'login',  to: 'sessions#new',     as: 'login'
	post   'login',  to: 'sessions#create'
	delete 'logout', to: 'sessions#destroy', as: 'logout'

	get "signup",       to: "admins#new",          as: "signup"
	post "signup",      to: "admins#create"
	get "verify_code",  to: "admins#verify_code",  as: "verify_code"
	post "confirm_code",to: "admins#confirm_code", as: "confirm_code"
	post "resend_code", to: "admins#resend_code",  as: "resend_code"

	get "dashboard", to: "admins#dashboard", as: "dashboard"

	# Scope routes under event
	scope '/events/:event_slug' do
		get    "dashboard", to: "admins#dashboard", as: "event_dashboard"
		get    "settings",  to: "admins#settings",  as: "event_settings"
		
		post   "/participants/:id/set_balance", to: "admins#set_balance", as: "event_set_balance"
		post   "participants/bulk_earn",         to: "admins#bulk_earn",  as: "event_bulk_earn"
		post   "/participants/:id/earn",         to: "admins#earn",       as: "event_earn"
		post   "/participants/:id/buy",          to: "admins#buy",        as: "event_buy"
		post   "/participants/:id/check_in",     to: "admins#check_in_participant", as: "event_participant_check_in"
		delete "/participants/:id",               to: "admins#delete_participant", as: "event_participant_delete"

		post   "/products/create",                to: "admins#create_product", as: "event_create_product"
		post   "/products/:id/edit",              to: "admins#update_product", as: "event_update_product"
		delete "/products/:id",                   to: "admins#delete_product", as: "event_product_delete"
		
		get    "products",                        to: "home#products",     as: "event_products"
		get    "products/refresh",                to: "products#refresh"
		
		get    "activity",                        to: "admins#activity",  as: "event_activity"
		get    "activity/refresh",                to: "admins#activity_refresh"
		
		get    "transactions",                    to: "admins#transactions", as: "event_transactions"
		get    "transactions/refresh",            to: "admins#transactions_refresh"
	end

	# Admin creation and sync routes outside event scope (if global)
	post 'admins/create',          to: 'admins#create',          as: 'admin_create'
	post 'admins/sync_participants', to: 'admins#sync_participants', as: 'sync_participants'

	# Root path
	root "home#index"
end
