class AdminsController < ApplicationController
    before_action :require_admin, except: [:new, :create, :verify_code, :confirm_code, :resend_code]
    before_action :require_signup_token, only: [ :verify_code, :confirm_code, :resend_code]

    def index
    end

    def new
        # Render the signup form
        if session[:admin_id].present?
            redirect_to dashboard_path, alert: "You are already logged in."
        else
            @admin = Admin.new
        end
    end

    def dashboard
    end

    def pending_invitations
        @pending_invitations = AdminInvitation.where(admin_id: @admin.id,status: 'pending')
        if @pending_invitations.empty?
            flash[:alert] = "You have no pending invitations."
            redirect_to dashboard_path
            return
        end
    end

    def accept_invitation
        invitation = @admin.invitations.find_by(id: params[:id], status: 'pending')
        if invitation
            result = invitation.accept!
            if result[:success]
                redirect_to dashboard_path, notice: 'Invitation accepted successfully.'
            else
                redirect_to pending_invitations_path, alert: result[:message] || 'Failed to accept invitation.'
            end
        else
            redirect_to pending_invitations_path, alert: 'Invitation not found or already accepted/rejected.'
        end
    end
    def reject_invitation
        invitation = @admin.invitations.find_by(id: params[:id], status: 'pending')
        if invitation
            result = invitation.reject!
            if result[:success]
                redirect_to pending_invitations_path, notice: 'Invitation rejected successfully.'
            else
                redirect_to pending_invitations_path, alert: result[:message] || 'Failed to reject invitation.'
            end
        else
            redirect_to pending_invitations_path, alert: 'Invitation not found or already accepted/rejected.' + invitation.inspect + params.inspect
        end
    end

    def settings
    end

    def create
        name = params[:name].strip.downcase
        password = params[:password].strip
        password_confirmation = params[:password_confirmation].strip
        email = params[:email].strip.downcase

        if name.present? && password.present? && password == password_confirmation && email.present?
            if Admin.exists?(name: name)
                redirect_to signup_path, alert: "Username already exists. Try another one." 
            elsif Admin.exists?(email: email)
                redirect_to signup_path, alert: "Email already exists. Try another one."
            else
                code = rand(100_000..999_999)
                begin
                    AdminMailer.send_code(email, code).deliver_now
                rescue => e
                    redirect_to signup_path, alert: "Failed to send verification email: #{e.message}"
                    return
                end
                exp = 30.minutes.from_now
                data_token = DataToken.create!(
                    data: {
						name: name,
						email: email,
						password: password,
						code: code
					}
				)
		        token = JWT.encode({
                    type: "signup",
					data_token_id: data_token.id,
					exp: exp.to_i
				}, Rails.application.secret_key_base)
                redirect_to verify_code_path(token: token)
            end

        else
            redirect_to signup_path, alert: 'Please fill all fields correctly.'
        end
    end
    def resend_code
        pending_admin = @pending_admin
        code = pending_admin["code"]
        email = pending_admin["email"]
        token = params[:token]
        AdminMailer.send_code(email, code).deliver_now
        redirect_to verify_code_path(token: token), notice: 'Code has been resent to your email.'
    rescue => e
        redirect_to signup_path, alert: "Failed to resend code: #{e.message}" 
    end

    def verify_code
        @token = params[:token]
    end
  
    def confirm_code
        entered_code = params[:code].strip
        pending_admin = @pending_admin
        token = @token
        if Admin.exists?(name: pending_admin["name"]) or Admin.exists?(email: pending_admin["email"])
            redirect_to signup_path, alert: "Username or email already exists. Try another one."
            return
        end
        if pending_admin["code"].to_s == entered_code.to_s
            result = Admin.new!(name: pending_admin["name"], password: pending_admin["password"], email: pending_admin["email"])
            if result[:success]
                pending_admin = nil
                redirect_to login_path, notice: 'Admin was successfully created.'
            else
                redirect_to verify_code_path(token: token), alert: result[:message]
            end
        else
            redirect_to verify_code_path(token: token), alert: 'Invalid code. Please try again.'
        end
    end

    def change_email
        new_email = params[:email].strip.downcase
        if new_email.present? && new_email != @admin.email
            if Admin.exists?(email: new_email)
                redirect_to settings_path, alert: "Email already exists. Try another one."
            else
                token = JWT.encode({
                    admin_id: @admin.id,
                    new_email: new_email,
                    exp: 1.hour.from_now.to_i
                }, Rails.application.secret_key_base)
                link = root_url + "settings/change_email/confirm?token=#{token}"
                AdminMailer.send_change_email(new_email, link).deliver_now
                redirect_to settings_path, notice: 'Confirmation email has been sent to your new email address. Please check your inbox.'
            end
        else
            redirect_to settings_path, alert: 'Please enter a valid email.'
        end

    end

    def change_email_confirm
        token = params[:token]
        begin
            decoded = JWT.decode(token, Rails.application.secret_key_base)[0]
            admin_id = decoded['admin_id']
            new_email = decoded['new_email']

            admin = Admin.find(admin_id)
            if admin
                if admin.email == new_email
                    redirect_to settings_path, alert: 'New email cannot be the same as the current email.'
                    return
                end
                admin.update!(email: new_email)
                redirect_to settings_path, notice: 'Email was successfully changed.'
            else
                redirect_to settings_path, alert: 'Admin not found.'
            end
        rescue JWT::ExpiredSignature
            redirect_to settings_path, alert: 'Token has expired. Please request a new email change.'
        rescue JWT::DecodeError
            redirect_to settings_path, alert: 'Invalid token. Please request a new email change.'
        end
    end

    def new_event

    end

    def create_event
        begin
            name = params[:name].strip
            description = params[:description].strip
            date = params[:date].strip
            sync_with_airtable = params[:sync_with_airtable] == '1' # Convert to boolean
            new_event = Event.create!(name: name, description: description,date:date, manager_id: @admin.id, sync_with_airtable: sync_with_airtable)
            redirect_to event_dashboard_path(new_event.slug), notice: 'Event was successfully created.'
        rescue => e
            redirect_to dashboard_path, alert: "Failed to create event: #{e.message}" 
        end
    end


    private

    def require_admin
        unless session[:admin_id].present? && Admin.exists?(session[:admin_id])
            session[:admin_id] = nil
            redirect_to login_path
            return
        end
        @admin = Admin.find(session[:admin_id])
    end

    def require_signup_token
        if params[:token].present?
            begin
                decoded_jwt = JWT.decode(params[:token], Rails.application.secret_key_base)[0]
                decoded = DataToken.find(decoded_jwt["data_token_id"]).data
                if decoded_jwt['exp'] < Time.now.to_i
                    redirect_to signup_path, alert: 'Token has expired. Please start the signup process again.'
                    return
                end
                @pending_admin = {
                    "name" => decoded["name"],
                    "email" => decoded["email"],
                    "password" => decoded["password"],
                    "code" => decoded["code"]  
                }
                @token = params[:token]
                if Admin.exists?(name: @pending_admin["name"]) or Admin.exists?(email: @pending_admin["email"])
                    redirect_to signup_path, alert: "Username or email already exists. Try another one."
                    return
                end
            rescue JWT::DecodeError
                redirect_to signup_path, alert: 'Invalid token. Please start the signup process again.'
                return
            end
        else
            redirect_to signup_path, alert: 'Token is required.' + params.inspect + params[:token].inspect + params[:code].inspect
            return
        end
    end
end
