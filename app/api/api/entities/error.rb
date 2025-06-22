module Api
    module Entities
        class Error < Grape::Entity
            expose :message, documentation: { type: 'String', desc: 'Error message' }
            expose :code, documentation: { type: 'Integer', desc: 'Error code' }
            def self.entity_name
                'Error'
            end
        end
    end
end