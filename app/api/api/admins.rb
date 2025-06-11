module Api
  class Admins < Grape::API
    format :json
    prefix :api

    # helpers Api::Helpers
    # before except: [:signup, :forgot_password, :resend_code, :confirm_code] do
    #   require_admin!
    # end

    resource :signup do
        desc 'Create admin'
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

      desc 'Forgot password'
      get :forgot_password do
        error!({ message: 'Password reset not implemented' }, 501)
      end

      desc 'Resend code'
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

      desc 'Confirm code'
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
					{ message: 'Admin created successfully', admin: { name: admin.name, email: admin.email } }  # status 201 REMEMBER TO INCLUDE
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

      desc 'Pending invitations'
      get :pending_invitations do
        require_admin!
        invitations = @admin.invitations.pending
        invitations
      end

      desc 'Accept invitation'
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

      desc 'Reject invitation'
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

      desc 'Create event'
      params do
        requires :name, type: String
        optional :description, type: String
        requires :date, type: Date
        optional :manager_id, type: Integer
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

      desc 'List events'
      get :events do
        require_admin!
        events = @admin.events + @admin.managed_events
        events
      end

      desc 'Admin settings'
      get :settings do
        require_admin!
        { admin: @admin }
      end
    end
  end
end
