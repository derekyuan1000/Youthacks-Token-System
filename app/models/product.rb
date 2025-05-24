class Product < ApplicationRecord
    # def self.create(name,price,description,quantity)
    #     Product.create(
    #         name:name,
    #         price:price,
    #         description:description,
    #         quantity:quantity
    #     )
    # end

    def change_price(new_price)
        # Activity.create!(
        #     product_id: id,
        #     action: "change_price",
        #     metadata: {old_cost: price, new_cost:new_price}.to_json,
        #     admin_id: admin_id,
        # )
        update(price: price)
        end
    def change_quantity(quantity)
        update(quantity: quantity)
    end
end
