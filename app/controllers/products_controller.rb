class ProductsController < ApplicationController

  def index
    @products = Product.all
  end

  def create
    name = params[:name]
    price = params[:price]
    description = params[:description]
    quantity = params[:quantity]
    puts "Name: #{name}", "Price: #{price}", "Description: #{description}", "Quantity: #{quantity}"
    Product.create(name: name, price: price, description: description, quantity: quantity)
    redirect_to products_path, notice: 'Product was successfully created.'

  end
  def update
    product = Product.find(params[:id])
    name = params[:name]
    price = params[:price]
    description = params[:description]
    quantity = params[:quantity]
    puts "Product ID: #{product.id}", "Name: #{name}", "Price: #{price}", "Description: #{description}", "Quantity: #{quantity}"
    if product.update!(name: name, price: price, description: description, quantity: quantity)
      redirect_to products_path, notice: 'Product was successfully updated.'
    else
      render :edit
    end
  end

  private

#   def set_product
#     @product = Product.find(params[:id])
#   end

#   def product_params
#     params.require(:product).permit(:name, :description, :price)
#   end
end