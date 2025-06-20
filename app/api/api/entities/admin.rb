require 'grape-entity'
module Api
	module Entities
		module Admin
			class Public < Grape::Entity
				expose :name, documentation: { type: 'String', desc: 'Admin name' }
				def self.entity_name
					'Admin_Public'
				end
			end

			class Full < Public
				expose :email, documentation: { type: 'string', format: 'email', desc: 'Admin email' }
				def self.entity_name
					'Admin_Full'
				end 
			end
		end
	end
end