class Admin < ApplicationRecord
    has_many :activities, as: :subject
    has_and_belongs_to_many :events, join_table: 'event_admins'
    has_many :managed_events, class_name: "Event", foreign_key: :manager_id
    # app/models/admin.rb
    has_many :invitations, class_name: "AdminInvitation", dependent: :destroy

    
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
