class Admin < ApplicationRecord
    has_many :activities, as: :subject
    has_secure_password

    def self.new!(name:, password:, admin_id:)
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
            Activity.create!(
                subject: new_admin,
                action: "admin_create",
                metadata: { name: name }.to_json,
                admin_id: admin_id
            )
            puts "Admin created successfully"
            { success: true, message: "Admin created successfully" }
        rescue => e
            { success: false, message: "Error creating admin: #{e.message}" }
        end
    end

    
end
