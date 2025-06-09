module API
    module Entities
        class Activity < Grape::Entity
            expose :id, documentation: { type: 'Integer', desc: 'Activity ID' }
            expose :action, documentation: { type: 'String', desc: 'Action performed in the activity' }
            expose :metadata, documentation: { type: 'JSON', desc: 'Additional metadata related to the activity' }
            expose :created_at, documentation: { type: 'DateTime', desc: 'Date and time when the activity was created' }
            expose :subject_type, documentation: { type: 'String', desc: 'Type of the subject involved in the activity' } do |activity, _opts|
                activity.subject_type if activity.subject
            end
            expose :subject, documentation: { type: 'Object', desc: 'Polymorphic subject of the activity' } do |activity, _opts|
                case activity.subject
                    when ::Participant
                        API::Entities::Participant::Public.represent(activity.subject)
                    when ::Product
                        API::Entities::Product.represent(activity.subject)
                    when ::Admin
                        API::Entities::Admin::Public.represent(activity.subject)
                    when ::Event
                        API::Entities::Event::Public.represent(activity.subject)
                    else
                        nil
                end
            end
            expose :admin, using: API::Entities::Admin::Public, documentation: { type: 'Admin', desc: 'Admin who performed the activity' } do |activity, _opts|
        end
    end
end