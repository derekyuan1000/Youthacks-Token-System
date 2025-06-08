module API
    module Entities
        class Participant < Grape::Entity
            expose :id, documentation: { type: 'Integer', desc: 'Participant ID' }
            expose :name, documentation: { type: 'String', desc: 'Participant name' }
            expose :balance, documentation: { type: 'Integer', desc: 'Participant balance' }
            expose :personal_info, doclumentation: { type: 'JSON', desc: 'Participant personal information' }
            expose :checked_in, documentation: { type: 'Boolean', desc: 'Whether the participant is checked in' }
            expose :check_in_time, documentation: { type: 'DateTime', desc: 'Check-in time of the participant' }
            expose :uuid, documentation: { type: 'String', desc: 'Unique identifier for the participant' }
        end
    end