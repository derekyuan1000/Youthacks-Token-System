

namespace :product do
    desc "Create Product"
    task create: :environment do
        prod = ENV["NAME"]
        desc = ENV["DESC"]
        amt = (ENV["PRICE"] || 1).to_i
        qty = (ENV["QUANTITY"] || 1).to_i

        Product.create!(name:prod, description:desc, price:amt, quantity:qty);

        puts "Product created: #{prod}"
    end
    desc "Buy Product"
    task buy: :environment do
        pid = ENV["PID"]
        prodid = (ENV["PRODID"] || 1).to_i

        participant = Participant.find_by(id: pid)
        product = Product.find_by(id: prodid)

        if product
            participant.buy!(product)
            puts "Balance updated: #{participant.balance}"
        else
            puts "Participant with ID #{pid} not found."
        end
    end

    desc "Change Product Price"
    task price: :environment do
        prodid = (ENV["PRODID"] || 1).to_i
        amt = (ENV["PRICE"] || 1).to_i

        product = Product.find_by(id: prodid)

        if product
            product.change_price(amt)
            puts "Product price updated: #{product.price}"
        else
            puts "Product with ID #{prodid} not found."
        end
    end
    desc "Change Product Quantity"
    task quantity: :environment do
        prodid = (ENV["PRODID"] || 1).to_i
        qty = (ENV["QUANTITY"] || 1).to_i

        product = Product.find_by(id: prodid)

        if product
            product.change_quantity(qty)
            puts "Product quantity updated: #{product.quantity}"
        else
            puts "Product with ID #{prodid} not found."
        end
    end
end
