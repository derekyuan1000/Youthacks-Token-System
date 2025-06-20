module Api
    module Entities
        module Event
            class Public < Grape::Entity
                expose :name, documentation: { type: 'String', desc: 'Event name' }
                expose :date, documentation: { type: 'Date', desc: 'Event date' }
                expose :description, documentation: { type: 'String', desc: 'Event description' }, unless: ->(event, _) { event.description.nil? }
                expose :slug, documentation: { type: 'String', desc: 'Event slug' }
                expose :manager, using: Api::Entities::Admin::Public, documentation: { type: 'Admin', desc: 'Event manager' }
                def self.entity_name
                    'Event_Public'
                end
            end

            class Member < Public
                expose :participants, using: Api::Entities::Participant::Public, documentation: { type: 'Array[Participant]', desc: 'List of participants in the event' }
                expose :admins, using: Api::Entities::Admin::Public, documentation: { type: 'Array[Admin]', desc: 'List of admins managing the event' }
                def self.entity_name
                    'Event_Admin'
                end
            end

            class Full < Member
                expose :sync_with_airtable, documentation: { type: 'Boolean', desc: 'Whether the event is synced with Airtable' }
                expose :airtable_api_key, documentation: { type: 'String', desc: 'Airtable API key' }
                expose :airtable_base_id, documentation: { type: 'String', desc: 'Airtable base ID' }
                expose :airtable_table_name, documentation: { type: 'String', desc: 'Airtable table name' }
                expose :name_column, documentation: { type: 'String', desc: 'Name column in Airtable' }
                def self.entity_name
                    'Event_Manager'
                end
            end
        end
    end
end