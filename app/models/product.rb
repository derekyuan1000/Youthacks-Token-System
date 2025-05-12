class Product < ApplicationRecord
    def self.create(name,price,description,quantity)
        Product.create(
            name:name,
            price:price,
            description:description,
            quantity:quantity
        )
    end

    
end
