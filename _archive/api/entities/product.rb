module API
    module Entities
        class Product < Grape::Entity
            expose :id, documentation: { type: 'Integer', desc: 'Admin ID' }
            expose :name, documentation: { type: 'String', desc: 'Admin name' }
            expose :price, documentation: { type: 'Integer', desc: 'Product price' }
            expose :description, documentation: { type: 'String', desc: 'Product description' }
            expose :quantity, documentation: { type: 'Integer', desc: 'Product quantity' }
            expose :email, documentation: { type: 'String', desc: 'Admin email' }
        end
    end
end