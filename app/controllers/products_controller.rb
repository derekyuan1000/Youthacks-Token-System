class ProductsController < ApplicationController

  def index
    @products = Product.all
  end

  def refresh
    @products = Product.all
    render partial: "home/products", locals: { products: @products }
  end

  private

#   def set_product
#     @product = Product.find(params[:id])
#   end

#   def product_params
#     params.require(:product).permit(:name, :description, :price)
#   end
end