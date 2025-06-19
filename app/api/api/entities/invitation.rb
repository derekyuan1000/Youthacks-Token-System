module Api
    module Entities
        class Invitation < Grape::Entity
            expose :id, documentation: { type: 'Integer', desc: 'ID of the invitation' }
            expose 
            expose :email, documentation: { type: 'String', desc: 'Email address of the invited user' }
            expose :status, documentation: { type: 'String', desc: 'Status of the invitation (e.g., pending, accepted)' }
            expose :event_slug, documentation: { type: 'String', desc: 'Slug of the associated event' } do |invitation|
                invitation.event&.slug
            end
            expose :created_at, documentation: { type: 'DateTime', desc: 'Timestamp when the invitation was created' }
            expose :updated_at, documentation: { type: 'DateTime', desc: 'Timestamp when the invitation was last updated' }
            def self.entity_name
                'Invitation'
            end
        end
    end
end