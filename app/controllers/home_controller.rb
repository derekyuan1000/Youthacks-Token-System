class HomeController < ApplicationController
  before_action :require_admin
  def index
    @admin = Admin.find_by(id: session[:admin_id]) # Check if an admin is logged in
  end

  def products
    @products = Product.all
  end

  private
  def require_admin
    if session[:admin_id].present? && Admin.exists?(session[:admin_id])
      @admin = Admin.find(session[:admin_id])
    end
  end
end