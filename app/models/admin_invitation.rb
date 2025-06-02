class AdminInvitation < ApplicationRecord
	belongs_to :event
	belongs_to :admin
	has_many :activities, as: :subject
	validates :status, presence: true, inclusion: { in: %w[pending accepted declined] }
	scope :pending, -> { where(status: 'pending') }

	def self.create!(event_id:, admin_id:)
		begin
			unless event_id.present? and Event.exists?(event_id)
				raise "Event ID is required and must be valid"
			end
			event = Event.find(event_id)
			unless admin_id.present? and Admin.exists?(admin_id) and event.manager_id != admin_id and !event.admins.exists?(admin_id)
				raise "Admin ID is required and must be valid"
			end
			if AdminInvitation.exists?(event_id: event_id, admin_id: admin_id, status: "pending")
				raise "Admin invitation already exists for this event and admin"
			end
			invitation = super(event_id: event_id, admin_id: admin_id, status: "pending")
			admin = Admin.find(admin_id)
			AdminMailer.invitation(event, admin).deliver_now
			Activity.create!(
				subject: invitation,
				action: "admin_invitation_create",
				metadata: { event_id: event_id, admin_id: admin_id }.to_json,
				admin_id: event.manager_id,
				event_id: event_id
			)
			{ success: true, message: "Admin invitation to #{admin.name} created successfully" }
		rescue => e
			{ success: false, message: "Error creating admin invitation: #{e.message}" }
		end
	end

	def accept!
		unless status == "pending"
			raise "Invitation is not pending"
		end
		update(status: "accepted")
		event.admins << admin unless event.admins.exists?(admin.id)
		Activity.create!(
			subject: self,
			action: "admin_invitation_accept",
			metadata: { event_id: event_id, admin_id: admin_id }.to_json,
			admin_id: admin_id,
			event_id: event_id
		)
		{ success: true, message: "Invitation accepted successfully" }
	rescue => e
		{ success: false, message: "Error accepting invitation: #{e.message}" }
	end

	def reject!
		unless status == "pending"
			raise "Invitation is not pending"
		end
		update(status: "declined")
		Activity.create!(
			subject: self,
			action: "admin_invitation_reject",
			metadata: { event_id: event_id, admin_id: admin_id }.to_json,
			admin_id: admin_id,
			event_id: event_id
		)
		{ success: true, message: "Invitation rejected successfully" }
	rescue => e
		{ success: false, message: "Error rejecting invitation: #{e.message}" }
	end

end
