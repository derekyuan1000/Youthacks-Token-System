module Api
    module Entities
        class Token < Grape::Entity
            expose :token, documentation: { type: 'String', desc: 'Token' }
            expose :message, documentation: { type: 'String', desc: 'Message' }
            expose :expires_at, documentation: { type: 'DateTime', desc: 'Expiration time of the token' }
        end
    end
end