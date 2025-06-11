module Api
    module Entities
        class Transaction < Grape::Entity
            expose :id, documentation: { type: 'Integer', desc: 'Transaction ID' }
            expose :product, using: Api::Entities::Product, documentation: { type: 'Product', desc: 'Product associated with the transaction' }
            expose :price, documentation: { type: 'Integer', desc: 'Transaction price' }
            expose :created_at, documentation: { type: 'DateTime', desc: 'Transaction date and time' }
            expose :participant, using: Api::Entities::Participant::Public, documentation: { type: 'Participant', desc: 'Participant involved in the transaction' }
        end
    end