class HomeController < ApplicationController
#   before_action :require_admin
	before_action :require_event, only: [:products, :products_refresh]
	def index
		@admin = Admin.find_by(id: session[:admin_id]) # Check if an admin is logged in
	end
	def products
		@products = @event.products.active
		if session[:admin_id].present? && Admin.exists?(session[:admin_id])
			@admin = Admin.find(session[:admin_id])
		end
    end
	def products_refresh
        @products = @event.products.active
        render partial: "home/products", locals: { products: @products }
    end

  	private
  	def require_event
        begin 
            event = Event.friendly.find(params[:event_slug])
            unless event.present?
                redirect_to dashboard_path, alert: "Event not found."
                return
            else
                @event = event
            end
        rescue => e
            redirect_to dashboard_path, alert: "Event does not exist."
        end
    end
#   def require_admin
#     if session[:admin_id].present? && Admin.exists?(session[:admin_id])
#       @admin = Admin.find(session[:admin_id])
#     end
#   end
end