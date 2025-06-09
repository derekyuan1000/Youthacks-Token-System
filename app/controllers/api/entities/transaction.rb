module API
    module Entities
        class Transaction < Grape::Entity
            expose :id, documentation: { type: 'Integer', desc: 'Transaction ID' }
            expose :product, using: API::Entities::Product, documentation: { type: 'Product', desc: 'Product associated with the transaction' }
            expose :price, documentation: { type: 'Integer', desc: 'Transaction price' }
            expose :created_at, documentation: { type: 'DateTime', desc: 'Transaction date and time' }
            expose :participant, using: API::Entities::Participant::Public, documentation: { type: 'Participant', desc: 'Participant involved in the transaction' }
        end
    end