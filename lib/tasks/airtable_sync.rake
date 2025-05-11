# lib/tasks/airtable_sync.rake

namespace :airtable do
  desc 'Sync participants from Airtable to local database'
  task sync: :environment do
    Participant.sync
  end
end
