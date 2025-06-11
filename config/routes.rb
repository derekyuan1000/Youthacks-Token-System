Rails.application.routes.draw do
	resources :admins

	get "sessions/new"
	get "sessions/create"
	get "sessions/destroy"
	get "up" => "rails/health#show", as: :rails_health_check

  # Docs API routes
	namespace :docs do
		namespace :api do
			get '/', to: 'api#docs', as: :api_docs
		end
	end

  mount Api::Base => '/'

	# Health check endpoint

	get    'login',  to: 'sessions#new',     as: 'login'
	post   'login',  to: 'sessions#create'
	delete 'logout', to: 'sessions#destroy', as: 'logout'
	get "forgot_password", to: "sessions#forgot_password", as: "forgot_password"

	get "signup",       to: "admins#new",          as: "signup"
	post "signup",      to: "admins#create"
	post "verify_code",  to: "admins#verify_code",  as: "verify_code"
	post "confirm_code", to: "admins#confirm_code", as: "confirm_code"
	post "resend_code", to: "admins#resend_code",  as: "resend_code"

	get "dashboard", to: "admins#dashboard", as: "dashboard"
	get "settings",  to: "admins#settings",  as: "settings"

	get "pending_invitations", to: "admins#pending_invitations", as: "pending_invitations"
	post "accept_invitation/:id", to: "admins#accept_invitation", as: "accept_invitation"
	delete "reject_invitation/:id", to: "admins#reject_invitation", as: "reject_invitation"


	get "create_event", to: "admins#new_event", as: "new_event"
	post "create_event", to: "admins#create_event", as: "create_event"

	# Scope routes under event
	scope '/events/:event_slug' do
		get    "dashboard", to: "events#dashboard", as: "event_dashboard"
		# get    "settings",  to: "admins#settings",  as: "event_settings"
		
		post "participants/create", to: "events#create_participant", as: "event_create_participant"
		post "participants/sync", 		to: "events#sync_participants", as: "event_sync_participants"
		post   "/participants/:id/set_balance", to: "events#set_balance", as: "event_set_balance"
		post   "participants/bulk_earn",         to: "events#bulk_earn",  as: "event_bulk_earn"
		post   "/participants/:id/earn",         to: "events#earn",       as: "event_earn"
		post   "/participants/:id/buy",          to: "events#buy",        as: "event_buy"
		post   "/participants/:id/check_in",     to: "events#check_in_participant", as: "event_participant_check_in"
		post  "participants/bulk_check_in",    to: "events#bulk_check_in", as: "event_bulk_check_in"
		delete "/participants/:id",               to: "events#delete_participant", as: "event_participant_delete"

		post   "/products/create",                to: "events#create_product", as: "event_create_product"
		post   "/products/:id/edit",              to: "events#update_product", as: "event_update_product"
		delete "/products/:id",                   to: "events#delete_product", as: "event_product_delete"
		
		get    "products",                        to: "home#products",     as: "event_products"
		get    "products/refresh",                to: "home#products_refresh", as: "event_products_refresh"
		
		get    "activity",                        to: "events#activity",  as: "event_activity"
		get    "activity/refresh",                to: "events#activity_refresh"
		
		get    "transactions",                    to: "events#transactions", as: "event_transactions"
		get    "transactions/refresh",            to: "events#transactions_refresh"

		get   "settings",                        to: "managers#settings", as: "event_settings"
		post "settings/update",                to: "managers#update_settings", as: "event_update_settings"
		post "settings/update_airtable", to: "managers#update_airtable", as: "event_update_airtable"
		post "settings/update_airtable_table", to: "managers#update_airtable_table", as: "event_update_airtable_table"

		get "admins", to: "managers#admins", as: "event_admins"
		post "admins/invite", to: "managers#invite_admin", as: "event_invite_admin"


		get "", to: "events#dashboard"
	end

	# Root path
	root "home#index"

	# Catch-all route for unmatched paths
	# match '*unmatched', to: 'application#route_not_found', via: :all
end
