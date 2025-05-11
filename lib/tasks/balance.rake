

namespace :balance do
    desc "Increase balance of a participant"
    task increase: :environment do
        pid = ENV["ID"]
        amt = (ENV["AMOUNT"] || 1).to_f

        participant = Participant.find_by(participant_id: pid)

        if participant
        participant.increase_balance!(amt)
        puts "Balance updated: #{participant.balance}"
        else
        puts "Participant with ID #{pid} not found."
        end
    end
    desc "Set balance of a participant"
    task set: :environment do
        pid = ENV["ID"]
        amt = (ENV["AMOUNT"] || 1).to_f

        participant = Participant.find_by(participant_id: pid)

        if participant
        participant.set_balance!(amt)
        puts "Balance updated: #{participant.balance}"
        else
        puts "Participant with ID #{pid} not found."
        end
    end
end
