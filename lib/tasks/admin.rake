require 'io/console'

namespace :admin do
  desc "Create a new admin"
  task create: :environment do
    print "Enter admin name: "
    name = STDIN.gets.chomp

    print "Enter password: "
    password = STDIN.noecho(&:gets).chomp
    puts

    print "Confirm password: "
    password_confirmation = STDIN.noecho(&:gets).chomp
    puts

    if name.empty? || password.empty? || password_confirmation.empty?
      puts "Please provide NAME, PASSWORD, and PASSWORD_CONFIRMATION."
      next
    end

    if password != password_confirmation
      puts "Password and Password Confirmation do not match."
      next
    end

    begin
      Admin.create!(name: name, password: password, password_confirmation: password_confirmation)
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