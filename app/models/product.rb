class Product < ApplicationRecord
    has_many :activities, as: :subject

    # def self.create(name,price,description,quantity)
    #     Product.create(
    #         name:name,
    #         price:price,
    #         description:description,
    #         quantity:quantity
    #     )
    # end

    def change!(name:, price:, description:, quantity:)
        old_values = {
            name: self.name,
            price: self.price,
            description: self.description,
            quantity: self.quantity
        }

        update!(
            name: name,
            price: price,
            description: description,
            quantity: quantity
        )

        Activity.create!(
            subject_id: id,
            subject_type: "Product",
            action: "product_update",
            (old_values.keys.each_with_object({}) do |key, diff|
                if old_values[key] != binding.local_variable_get(key)
                    diff[:old_values] ||= {}
                    diff[:new_values] ||= {}
                    diff[:old_values][key] = old_values[key]
                    diff[:new_values][key] = binding.local_variable_get(key)
                end
            end).to_json
        )
    end
end
