class Product < ApplicationRecord
    has_many :activities, as: :subject

    def self.create(name:,price:,description:,quantity:, admin_id:)
        begin
            unless admin_id.present? and Admin.exists?(admin_id)
                raise "Admin ID is required and must be valid"
            end
            unless name.present?
                raise "Name cannot be blank"
            end
            unless price.present? and price.is_a?(Numeric) and price > 0 and quantity.present? and quantity.is_a?(Numeric) and quantity > 0
                raise "Price must be a positive number and quantity must be a non-negative integer"
            end
            price = price.to_i
            quantity = quantity.to_i
            values = {
                name: name,
                price: price,
                description: description,
                quantity: quantity
            }
            Activity.create!(
                subject_id: id,
                subject_type: "Product",
                action: "product_create",
                metadata: values.to_json,
                admin_id: admin_id
            )
            {success: true, message: "Product updated successfully"}
        end
        rescue => e
            { success: false, message: "Error updating product: #{e.message}" }
    end

    def delete!(admin_id:)
        begin
            unless admin_id.present? and Admin.exists?(admin_id)
                raise "Admin ID is required and must be valid"
            end
            Activity.create!(
                subject_id: id,
                subject_type: "Product",
                action: "product_delete",
                metadata: { name: name, price: price, description: description, quantity: quantity }.to_json,
                admin_id: admin_id
            )
            destroy!
            { success: true, message: "Product deleted successfully" }
        rescue => e
            { success: false, message: "Error deleting product: #{e.message}" }
        end
    end

    def change!(name:, price:, description:, quantity:, admin_id: )
        begin
            unless admin_id.present? and Admin.exists?(admin_id)
                raise "Admin ID is required and must be valid"
            end
            unless name.present?
                raise "Name cannot be blank"
            end
            unless price.present? and price.is_a?(Numeric) and price > 0 and quantity.present? and quantity.is_a?(Numeric) and quantity > 0
                raise "Price must be a positive number and quantity must be a non-negative integer"
            end
            puts "SHOULD NOT SEE THISSHOULD NOT SEE THISSHOULD NOT SEE THISSHOULD NOT SEE THISSHOULD NOT SEE THISSHOULD NOT SEE THISSHOULD NOT SEE THISSHOULD NOT SEE THISSHOULD NOT SEE THISSHOULD NOT SEE THISSHOULD NOT SEE THISSHOULD NOT SEE THISSHOULD NOT SEE THISSHOULD NOT SEE THISSHOULD NOT SEE THISSHOULD NOT SEE THISSHOULD NOT SEE THISSHOULD NOT SEE THISSHOULD NOT SEE THISSHOULD NOT SEE THISSHOULD NOT SEE THISSHOULD NOT SEE THISSHOULD NOT SEE THISSHOULD NOT SEE THISSHOULD NOT SEE THISSHOULD NOT SEE THISSHOULD NOT SEE THISSHOULD NOT SEE THISSHOULD NOT SEE THISSHOULD NOT SEE THISSHOULD NOT SEE THIS"
            price = price.to_i
            quantity = quantity.to_i
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
                metadata: (old_values.keys.each_with_object({}) do |key, diff|
                    if old_values[key] != binding.local_variable_get(key)
                    diff[:old_values] ||= {}
                    diff[:new_values] ||= {}
                    diff[:old_values][key] = old_values[key]
                    diff[:new_values][key] = binding.local_variable_get(key)
                    end
                end).to_json,
                admin_id: admin_id
            )
            {success: true, message: "Product updated successfully"}
        end
    rescue => e
        { success: false, message: "Error updating product: #{e.message}" }
    end
end
