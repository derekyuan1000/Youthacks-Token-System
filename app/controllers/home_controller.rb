class HomeController < ApplicationController
  def index
    @admin = Admin.find_by(id: session[:admin_id]) # Check if an admin is logged in
  end

  def products
    @products = Product.all
  end
end