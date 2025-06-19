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
	end

    before do
      exempt_paths = ['/api/signup', '/api/signup/resend_code', '/api/signup/confirm_code', '/api/login', '/api/forgot_password']
      clean_path = route.path.gsub(/\(\.:format\)/, '')
      unless exempt_paths.include?(clean_path)
        require_admin!
      end
    end
	#test
    resource :signup do
		desc 'Create admin' do
			summary 'Create a new admin account'
			detail 'Returns a JWT pending signup token for further verification'
			tags ['Signup']
			success Api::Entities::Token
			failure [[422, 'Validation failed', Api::Entities::Error]]
			nickname 'create_admin'
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
		
		desc 'Resend verification code', {
		  tags: ['Signup'],
		  detail: 'Resend verification code',
		  headers: {
		    Authorization: {
		      required: true,
		      type: 'string',
		      description: ' token from pending signup step'
		    }
		  },
		  documentation: { operationId: 'resend_signup_code',
			responses: {
			  200 => {
				description: 'Code resent successfully',
				schema: {
				  type: 'object',
				  properties: {
					message: { type: 'string' }
				  }
				}
			  }
			}
		  }
		}
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
		
		desc 'Confirm signup code', {
		  tags: ['Signup'],
		  detail: 'Confirm signup code',
		  headers: {
		    Authorization: {
		      required: true,
		      type: 'string',
		      description: 'Token from pending signup step'
		    }
		  },
		  documentation: { operationId: 'confirm_signup_code',
			responses: {
			  200 => {
				description: 'Admin created successfully',
				schema: {
				  type: 'object',
				  properties: {
					message: { type: 'string' },
					admin: {
					  type: 'object',
					  properties: {
						name: { type: 'string' },
						email: { type: 'string' }
					  }
					}
				  }
				}
			  }
			}
		  }
		}
		params do
			requires :code, type: String
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
	
	desc 'Forgot password', {
	  tags: ['User'],
	  detail: 'Forgot password',
	  documentation: { operationId: 'forgot_password',
		responses: {
		  501 => {
			description: 'Password reset not implemented'
		  }
		}
	  }
	}
	get :forgot_password do
		error!({ message: 'Password reset not implemented' }, 501)
	end

    desc 'Get pending invitations', {
      tags: ['Event Managers'],
      detail: 'Get pending invitations',
      headers: AUTH_HEADER_DOC,
      documentation: { operationId: 'list_pending_invitations',
		responses: {
		  200 => {
			description: 'List of pending invitations',
			schema: {
			  type: 'array',
			  items: { '$ref' => '#/definitions/Api::Entities::Invitation' }
			}
		  }
		}
	  }
    }
    params do
    end
    get :pending_invitations do
      invitations = @admin.invitations.pending
      present invitations, with: Api::Entities::Invitation
    end

    desc 'Accept invitation by ID', {
      tags: ['User'],
      detail: 'Accept invitation by ID',
      headers: AUTH_HEADER_DOC,
      documentation: { operationId: 'accept_invitation',
		responses: {
		  200 => {
			description: 'Invitation accepted',
			schema: {
			  type: 'object',
			  properties: {
				message: { type: 'string' }
			  }
			}
		  }
		}
	  }
    }
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

    desc 'Reject invitation by ID', {
      tags: ['User'],
      detail: 'Reject invitation by ID',
      headers: AUTH_HEADER_DOC,
      documentation: { operationId: 'reject_invitation',
		responses: {
		  200 => {
			description: 'Invitation rejected',
			schema: {
			  type: 'object',
			  properties: {
				message: { type: 'string' }
			  }
			}
		  }
		}
	  }
    }
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

    desc 'Create a new event', {
      tags: ['User'],
      detail: 'Create a new event',
      headers: AUTH_HEADER_DOC,
      documentation: { operationId: 'create_event',
		responses: {
		  200 => {
			description: 'Event created successfully',
			schema: { '$ref' => '#/definitions/Api::Entities::Event::Full' }
		  }
		}
	  }
    }
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

    desc 'List admin and managed events', {
      tags: ['User'],
      detail: 'List admin and managed events',
      headers: AUTH_HEADER_DOC,
      documentation: { operationId: 'list_events',
		responses: {
		  200 => {
			description: 'List of admin and managed events',
			schema: {
			  type: 'array',
			  items: { '$ref' => '#/definitions/Api::Entities::Event::Full' }
			}
		  }
		}
	  }
    }
    params do
    end
    get :events do
      events = @admin.events + @admin.managed_events
      present events, with: Api::Entities::Event::Full
    end

    desc 'Get admin settings', {
      tags: ['User'],
      detail: 'Get admin settings',
      headers: AUTH_HEADER_DOC,
      documentation: { operationId: 'get_admin_settings',
		responses: {
		  200 => {
			description: 'Admin settings returned',
			schema: { '$ref' => '#/definitions/Api::Entities::Admin::Full' }
		  }
		}
	  }
    }
    params do
    end
    get :settings do	
      present @admin, with: Api::Entities::Admin::Full
    end

    desc 'Login', {
      tags: ['User'],
      detail: 'Login',
      documentation: { operationId: 'login_admin',
		responses: {
		  200 => {
			description: 'Successful login with token',
			schema: {
			  type: 'object',
			  properties: {
				message: { type: 'string' },
				token: { type: 'string' }
			  }
			}
		  }
		}
	  }
    }
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
