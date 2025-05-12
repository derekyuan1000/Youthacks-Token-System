

namespace :participant do
    desc "Increase balance of a participant"
    task earn: :environment do
        pid = ENV["ID"]
        amt = (ENV["AMOUNT"] || 1).to_i

        participant = Participant.find_by(participant_id: pid)

        if participant
            participant.earn!(amt)
            puts "Balance updated: #{participant.balance}"
        else
            puts "Participant with ID #{pid} not found."
        end
    end
    desc "Set balance of a participant"
    task set: :environment do
        pid = ENV["ID"]
        amt = (ENV["AMOUNT"] || 1).to_i

        participant = Participant.find_by(participant_id: pid)

        if participant
            participant.set_balance!(amt)
            puts "Balance updated: #{participant.balance}"
        else
            puts "Participant with ID #{pid} not found."
        end
    end
end
