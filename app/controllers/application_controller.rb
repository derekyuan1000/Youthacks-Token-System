class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  def route_not_found
    redirect_to root_path, alert: "The page you are looking for does not exist."
  end
end
