module Api
  class Admins < Grape::API
    format :json
    prefix :api

    helpers do
		def require_admin!
            header = headers['Authorization']
            token = header&.split(' ')&.last

            error!({ error: 'Missing token' }, 401) if token.blank?

            begin
                decoded = JWT.decode(token, Rails.application.secret_key_base)[0]
                @admin = Admin.find(decoded['user_id'])
                rescue JWT::ExpiredSignature
                    error!({ error: 'Token expired' }, 401)
                rescue JWT::DecodeError
                    error!({ error: 'Invalid token' }, 401)
                rescue ActiveRecord::RecordNotFound
                    error!({ error: 'Admin not found' }, 401)
            end
        end
	end

    before do
		unless [:signup, :forgot_password, :resend_code, :confirm_code].include?(route.route_name)
			require_admin!
		end
    end

    resource :signup do
		desc 'Create admin', tags: ['Signup']
		params do
			requires :name, type: String
			requires :email, type: String
			requires :password, type: String
		end
		post do
			name = params[:name]
			password = params[:password]
			email = params[:email]

			if name.present? && password.present? && email.present?
			code = rand(100_000..999_999)
			AdminMailer.send_code(email, code).deliver_now

			pending_token = JWT.encode({
				name: name,
				email: email,
				password: password,
				code: code,
				exp: 30.minutes.from_now.to_i
			}, Rails.application.secret_key_base)
			{ token: pending_token }
			else
				error!({ message: 'Name, password, and email cannot be blank' }, 422)
			end
      	end
		
		desc 'Resend code', tags: ['Signup']
		post :resend_code do
			header = headers['Authorization']
			token = header&.split(' ')&.last
		
			error!({ error: 'Missing token' }, 401) if token.blank?
		
			begin
				decoded = JWT.decode(token, Rails.application.secret_key_base)[0]
				email = decoded['email']
				code = decoded['code']
				AdminMailer.send_code(email, code).deliver_now
				{ message: 'Code resent successfully' }
			rescue JWT::DecodeError
				error!({ message: 'Invalid token' }, 401)
			end
		end
		
		desc 'Confirm code', tags: ['Signup']
		params do
		requires :code, type: String
		end
		post :confirm_code do
			header = headers['Authorization']
			token = header&.split(' ')&.last
		
			error!({ message: 'Missing token' }, 401) if token.blank?
		
			begin
				decoded = JWT.decode(token, Rails.application.secret_key_base)[0]
				entered_code = params[:code].strip
				if decoded['code'].to_s == entered_code.to_s
				result = Admin.new!(name: decoded['name'], password: decoded['password'], email: decoded['email'])
				if result[:success]
					admin = result[:admin]
					{ message: 'Admin created successfully', admin: { name: admin.name, email: admin.email } }
				else
					error!({ message: admin.errors.full_messages.join(', ') || 'Failed to create admin' }, 422)
				end
				else
					error!({ message: 'Invalid code' }, 401)
				end
			rescue JWT::DecodeError
				error!({ message: 'Invalid token' }, 401)
			end
		end
	end
	desc 'Forgot password', tags: ['Auth']
	get :forgot_password do
		error!({ message: 'Password reset not implemented' }, 501)
	end

    desc 'Pending invitations', tags: ['Invitations']
    get :pending_invitations do
      require_admin!
      invitations = @admin.invitations.pending
      invitations
    end

    desc 'Accept invitation', tags: ['Invitations']
    params do
      requires :invitation_id, type: Integer
    end
    post :accept_invitation do
      require_admin!
      invitation = @admin.invitations.pending.find_by(id: params[:invitation_id])
      if invitation
        result = invitation.accept!
        if result[:success]
          { message: 'Invitation accepted' }
        else
          error!({ error: result[:message] || 'Failed to accept invitation' }, 422)
        end
      else
        error!({ error: 'Invitation not found' }, 404)
      end
    end

    desc 'Reject invitation', tags: ['Invitations']
    params do
      requires :invitation_id, type: Integer
    end
    post :reject_invitation do
      require_admin!
      invitation = @admin.invitations.pending.find_by(id: params[:invitation_id])
      if invitation
        invitation.reject!
        { message: 'Invitation rejected' }
      else
        error!({ error: 'Invitation not found or already processed' }, 404)
      end
    end

    desc 'Create event', tags: ['Events']
    params do
      requires :name, type: String
      optional :description, type: String
      requires :date, type: Date
      optional :sync_with_airtable, type: Boolean, default: false
    end
    post :create_event do
      require_admin!
      event_params = {
        name: params[:name],
        description: params[:description],
        date: params[:date],
        manager_id: @admin.id,
        sync_with_airtable: params[:sync_with_airtable]
      }
      event = @admin.events.create!(event_params)
      { event: event }
    end

    desc 'List events', tags: ['Events']
    get :events do
      require_admin!
      events = @admin.events + @admin.managed_events
      events
    end

    desc 'Admin settings', tags: ['Events']
    get :settings do	
      admin, with = Api::Entities::Admin::Full
    end
    desc 'Login and get JWT token', tags: ['Auth']
    params do
      requires :name, type: String
      requires :password, type: String
    end
    post :login do
		admin = Admin.find_by(name: params[:name])
		if admin && admin.authenticate(params[:password])
			payload = { user_id: admin.id, exp: 2.days.from_now.to_i }
			token = JWT.encode(payload, Rails.application.secret_key_base)
			{message: "Successful log in", token: token }
		else
			error!({ error: 'Invalid email or password' }, 401)
		end
  end
  end
end
