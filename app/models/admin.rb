class Admin < ApplicationRecord
    has_secure_password

    def self.new!(name, password)
        if Admin.exists?(name: name)
            raise "Admin with this name already exists"
        end
        Admin.create!(
            name: name,
            password: password
        )
    end

end
