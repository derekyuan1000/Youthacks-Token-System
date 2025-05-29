class Admin < ApplicationRecord
    has_many :activities, as: :subject
    has_secure_password

    def self.new!(name:, password:)
        puts "Creating new admin with name: #{name}, #{password}, admin_id: #{admin_id}"
        begin
            if Admin.exists?(name: name)
                raise "Admin with this name already exists"
            end
            unless name.present? and password.present?
                raise "Name and password cannot be blank"
            end
            new_admin = create!(
                name: name,
                password: password
            )
            puts "Admin created successfully"
            { success: true, message: "Admin created successfully" }
        rescue => e
            { success: false, message: "Error creating admin: #{e.message}" }
        end
    end

    
end
