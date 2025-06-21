require 'jwt' # Test fix just for docker on
module Api
  class Admins < Grape::API
    AUTH_HEADER_DOC = {
      Authorization: {
        required: true,
        type: 'string',
        description: ' token for admin authentication'
      }
    }.freeze

    format :json
    prefix :api

	helpers do
		def require_admin!
			header = headers['Authorization']
			token = header&.split(' ')&.last

			error!({ error: 'Missing token' }, 401) if token.blank?

			begin
				decoded = JWT.decode(token, Rails.application.secret_key_base)[0]
				error!({message: 'Invalid token type' }, 401) unless decoded['type'] == 'login'
				@admin = Admin.find(decoded['user_id'])
			rescue JWT::ExpiredSignature
				error!({ error: 'Token expired' }, 401)
			rescue JWT::DecodeError
				error!({ error: 'Invalid token' }, 401)
			rescue ActiveRecord::RecordNotFound
				error!({ error: 'Admin not found' }, 401)
			end
		end

		params :email_param do
			requires :email, type: String,
				format: URI::MailTo::EMAIL_REGEXP,
				documentation: { format: 'email'}
		end

		# Shared params for pending signup token
		params :pending_signup_token do
			requires :Authorization, type: String, documentation: {
				param_type: 'header',
				required: true,
				description: ' token from pending signup step'
			}
		end

    params :confirm_signup_code_params do
      requires :code, type: String, documentation: { type: 'string', desc: 'Signup confirmation code' }
    end
	end

    before do
      exempt_paths = ['/api/signup', '/api/signup/resend_code', '/api/signup/confirm_code', '/api/login', '/api/forgot_password']
      clean_path = route.path.gsub(/\(\.:format\)/, '')
      unless exempt_paths.include?(clean_path)
        require_admin!
      end
    end
    resource :signup do
		desc 'Create admin' do
			summary 'Create a new admin account'
			detail 'Returns a JWT pending signup token for further verification'
			tags ['Signup']
			success Api::Entities::Token
			failure [[422, 'Validation failed', Api::Entities::Error]]
		end
		params do
			requires :name, type: String
			use :email_param
			requires :password, type: String
		end
		post do
			name = params[:name]
			password = params[:password]
			email = params[:email]

			if name.present? && password.present? && email.present?
				error!({ message: 'Admin already exists' }, 422) if Admin.exists?(email: email) or Admin.exists?(name: name)
				error!({ message: 'Invalid email format' }, 422) unless email =~ URI::MailTo::EMAIL_REGEXP
				code = rand(100_000..999_999)
				AdminMailer.send_code(email, code).deliver_now
				exp_time = 30.minutes.from_now.to_i
				pending_token = JWT.encode({
					type: "signup",
					name: name,
					email: email,
					password: password,
					code: code,
					exp: exp_time
				}, Rails.application.secret_key_base)
				{ token: pending_token, message: 'Pending signup token created', expires_at: Time.at(exp_time) }
			else
				error!({ message: 'Name, password, and email cannot be blank' }, 422)
			end
      	end
		
		desc 'Resend verification code' do
			summary 'Resend the verification code for admin signup'
			detail 'Resends the verification code to the email address provided during the signup process'
			tags ['Signup']
			headers AUTH_HEADER_DOC
			success code: 200, message: 'Code resent successfully'
			failure [[401, 'Missing or invalid token', Api::Entities::Error], [422, 'Validation failed', Api::Entities::Error]]
		end
		post :resend_code do
			header = headers['Authorization']
			error!({ error: 'Missing token' }, 401) if header.blank?
			token = header&.split(' ')&.last
		
			begin
				decoded = JWT.decode(token, Rails.application.secret_key_base)[0]
				error!({message: 'Invalid token type' }, 401) unless decoded['type'] == 'signup'
				email = decoded['email']
				code = decoded['code']
				AdminMailer.send_code(email, code).deliver_now
				{ message: 'Code resent successfully' }
			rescue JWT::DecodeError
				error!({ message: 'Invalid token' }, 401)
			end
		end
		
		desc 'Confirm signup code' do
			summary 'Confirm the verification code for admin signup'
			detail 'Confirms the verification code and creates the admin account'
			tags ['Signup']
			headers AUTH_HEADER_DOC
			success Api::Entities::Admin::Public
			failure [[401, 'Invalid code or token', Api::Entities::Error], [422, 'Validation failed', Api::Entities::Error]]
		end
		params do
			use :confirm_signup_code_params
		end
		post :confirm_code do
			header = headers['Authorization']
			error!({ message: 'Missing token' }, 401) if header.blank?
			token = header&.split(' ')&.last
		
			begin
				decoded = JWT.decode(token, Rails.application.secret_key_base)[0]
				entered_code = params[:code].strip
				if decoded['code'].to_s == entered_code.to_s
					result = Admin.new!(name: decoded['name'], password: decoded['password'], email: decoded['email'])
					if result[:success]
						admin = result[:admin]
						present admin, with: Api::Entities::Admin::Public
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
	
	desc 'Forgot password' do
		summary 'Forgot password'
		detail 'Endpoint for password reset (not yet implemented)'
		tags ['User']
		success code: 501, message: 'Password reset not implemented'
	end
	get :forgot_password do
		error!({ message: 'Password reset not implemented' }, 501)
	end

    desc 'Get pending invitations' do
      summary 'List all pending invitations for the current admin'
      detail 'Returns all invitations that are pending and require action from the admin'
      tags ['Event Managers']
      headers AUTH_HEADER_DOC
      success Api::Entities::Invitation
      failure [[401, 'Unauthorized', Api::Entities::Error]]
    end
    params do
    end
    get :pending_invitations do
      invitations = @admin.invitations.pending
      present invitations, with: Api::Entities::Invitation
    end

    desc 'Accept invitation by ID' do
      summary 'Accept a pending invitation by its ID'
      detail 'Accepts the invitation and updates its status'
      tags ['User']
      headers AUTH_HEADER_DOC
      success code: 200, message: 'Invitation accepted'
      failure [[401, 'Unauthorized', Api::Entities::Error], [404, 'Invitation not found', Api::Entities::Error], [422, 'Failed to accept invitation', Api::Entities::Error]]
    end
    params do
      requires :invitation_id, type: Integer
    end
    post :accept_invitation do
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

    desc 'Reject invitation by ID' do
      summary 'Reject a pending invitation by its ID'
      detail 'Rejects the invitation and updates its status'
      tags ['User']
      headers AUTH_HEADER_DOC
      success code: 200, message: 'Invitation rejected'
      failure [[401, 'Unauthorized', Api::Entities::Error], [404, 'Invitation not found or already processed', Api::Entities::Error]]
    end
    params do
      requires :invitation_id, type: Integer
    end
    post :reject_invitation do
		invitation = @admin.invitations.pending.find_by(id: params[:invitation_id])
		if invitation
			invitation.reject!
			{ message: 'Invitation rejected' }
		else
			error!({ error: 'Invitation not found or already processed' }, 404)
		end
    end

    desc 'Create a new event' do
      summary 'Create a new event'
      detail 'Creates a new event managed by the current admin'
      tags ['User']
      headers AUTH_HEADER_DOC
      success Api::Entities::Event::Full
      failure [[401, 'Unauthorized', Api::Entities::Error], [422, 'Validation failed', Api::Entities::Error]]
    end
    params do
      requires :name, type: String
      optional :description, type: String
      requires :date, type: Date
      optional :sync_with_airtable, type: Boolean, default: false
    end
    post :create_event do
      event_params = {
        name: params[:name],
        description: params[:description],
        date: params[:date],
        manager_id: @admin.id,
        sync_with_airtable: params[:sync_with_airtable]
      }
      event = @admin.events.create!(event_params)
      present event, with: Api::Entities::Event::Full
    end

    desc 'List admin and managed events' do
      summary 'List all events for which the admin is responsible'
      detail 'Returns all events created or managed by the current admin'
      tags ['User']
      headers AUTH_HEADER_DOC
      success Api::Entities::Event::Full
      failure [[401, 'Unauthorized', Api::Entities::Error]]
    end
    params do
    end
    get :events do
      events = @admin.events + @admin.managed_events
      present events, with: Api::Entities::Event::Full
    end

    desc 'Get admin settings' do
      summary 'Get the current admin\'s settings'
      detail 'Returns the full settings and profile for the current admin'
      tags ['User']
      headers AUTH_HEADER_DOC
      success Api::Entities::Admin::Full
      failure [[401, 'Unauthorized', Api::Entities::Error]]
    end
    params do
    end
    get :settings do	
      present @admin, with: Api::Entities::Admin::Full
    end

    desc 'Login' do
      summary 'Admin login'
      detail 'Authenticates an admin and returns a JWT token for further requests'
      tags ['User']
      success Api::Entities::Token
      failure [[401, 'Invalid email or password', Api::Entities::Error]]
    end
    params do
      requires :name, type: String
      requires :password, type: String
    end
    post :login do
      admin = Admin.find_by(name: params[:name])
      if admin && admin.authenticate(params[:password])
        payload = {type: "login", user_id: admin.id, exp: 2.days.from_now.to_i }
        token = JWT.encode(payload, Rails.application.secret_key_base)
        { message: "Successful log in", token: token }
      else
        error!({ error: 'Invalid email or password' }, 401)
      end
    end
  end
end
