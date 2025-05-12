namespace :admin do
    desc "Create a new admin"
    task create: :environment do
        name = ENV["NAME"]
        password = ENV["PASSWORD"]
        password_confirmation = ENV["PASSWORD_CONFIRMATION"]

        if name.nil? || password.nil? || password_confirmation.nil?
            puts "Please provide NAME, PASSWORD, and PASSWORD_CONFIRMATION."
            next
        end
        if password != password_confirmation
            puts "Password and Password Confirmation do not match."
            next
        end
        begin
            Admin.new!(name, password)
            puts "Admin created successfully."
        rescue => e
            puts "Error creating admin: #{e.message}"
        end
    end

    desc "Authenticate an admin"
    task authenticate: :environment do
        name = ENV["NAME"]
        password = ENV["PASSWORD"]

        if name.nil? || password.nil?
            puts "Please provide both NAME and PASSWORD."
            next
        end

        begin
            admin = Admin.authenticate(name, password)
            puts "Admin authenticated successfully."
        rescue => e
            puts "Error authenticating admin: #{e.message}"
        end
    end
end