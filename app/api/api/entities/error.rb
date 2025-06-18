module Api
    module Entities
        class Error < Grape::Entity
            expose :error, documentation: { type: 'String', desc: 'Error message' }
            expose :code, documentation: { type: 'Integer', desc: 'Error code' }
        end
    end
end