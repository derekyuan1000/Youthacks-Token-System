class Admin < ApplicationRecord
    has_many :activities, as: :subject
    
    has_secure_password

    def self.new!(name:, password:, email:)
        begin
            if Admin.exists?(name: name)
                raise "Admin with this name already exists"
            end
            unless name.present? and password.present?
                raise "Name and password cannot be blank"
            end
            new_admin = create!(
                name: name,
                password: password,
                email: email
            )
            { success: true, message: "Admin created successfully" }
        rescue => e
            { success: false, message: "Error creating admin: #{e.message}" }
        end
    end

    
end
