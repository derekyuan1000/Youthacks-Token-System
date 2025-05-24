class Product < ApplicationRecord
    def self.create(name,price,description,quantity)
        Product.create(
            name:name,
            price:price,
            description:description,
            quantity:quantity
        )
    end

    def change_price(price)
        update(price: price)
    end
    def change_quantity(quantity)
        update(quantity: quantity)
    end
end
