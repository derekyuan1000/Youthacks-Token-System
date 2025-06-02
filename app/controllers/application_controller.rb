class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  protect_from_forgery with: :exception

  skip_before_action :verify_authenticity_token, if: -> { request.path.start_with?('/api') }

  def route_not_found
    redirect_to root_path, alert: "The page you are looking for does not exist."
  end
end
