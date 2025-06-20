module Api
    module Entities
        module Participant
            class Public < Grape::Entity
                expose :name, documentation: { type: 'String', desc: 'Participant name' }
                expose :balance, documentation: { type: 'Integer', desc: 'Participant balance' }
                def self.entity_name
                    'Participant_Public'
                end
            end
            class Full < Public
                expose :id, documentation: { type: 'Integer', desc: 'Participant ID' } 
                expose :personal_info,documentation: { type: 'JSON', desc: 'Participant personal information' }
                expose :checked_in, documentation: { type: 'Boolean', desc: 'Whether the participant is checked in' }
                expose :check_in_time, documentation: { type: 'DateTime', desc: 'Check-in time of the participant' }
                expose :uuid, documentation: { type: 'String', desc: 'Unique identifier for the participant' }
                def self.entity_name
                'Participant_Admin'
                end

                def self.entity_description
                    'Full view of a participant, including personal information and check-in status.'
                end
            end
        end
    end
end