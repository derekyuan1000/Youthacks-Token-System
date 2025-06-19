module Api
    module Entities
        class Error < Grape::Entity
            expose :error, documentation: { type: 'String', desc: 'Error message' }
            expose :code, documentation: { type: 'Integer', desc: 'Error code' }
            def self.entity_name
                'API Error'
            end
        end
    end
end