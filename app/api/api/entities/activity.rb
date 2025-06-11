module Api
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
                        Api::Entities::Participant::Public.represent(activity.subject)
                    when ::Product
                        Api::Entities::Product.represent(activity.subject)
                    when ::Admin
                        Api::Entities::Admin::Public.represent(activity.subject)
                    when ::Event
                        Api::Entities::Event::Public.represent(activity.subject)
                    else
                        nil
                end
            end
            expose :admin, using: Api::Entities::Admin::Public, documentation: { type: 'Admin', desc: 'Admin who performed the activity' } do |activity, _opts|
        end
    end
end