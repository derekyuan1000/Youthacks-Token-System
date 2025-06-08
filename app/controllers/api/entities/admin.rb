module API
  module Entities
    module Admin
      class Public < Grape::Entity
        expose :name, documentation: { type: 'String', desc: 'Admin name' }
      end

      class Full < Grape::Entity
        expose :name, documentation: { type: 'String', desc: 'Admin name' }
        expose :email, documentation: { type: 'string', format: 'email', desc: 'Admin email' }
      end
    end
  end
end