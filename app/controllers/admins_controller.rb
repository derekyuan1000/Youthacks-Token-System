class AdminsController < ApplicationController
    before_action :require_admin, except: [:new, :create, :verify_code, :confirm_code, :resend_code]

    def index
    end

    def new
        # Render the signup form
        if session[:admin_id].present?
            redirect_to event_dashboard_path, notice: "You are already logged in."
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
        name = params[:name].strip
        password = params[:password]
        password_confirmation = params[:password_confirmation]
        email = params[:email]

        if name.present? && password.present? && password == password_confirmation && email.present?
            code = rand(100_000..999_999)
            AdminMailer.send_code(email, code).deliver_now

            session[:pending_admin] = {
                name: name,
                password: password,
                email: email,
                code: code
            }

            redirect_to verify_code_path
        else
            redirect_to signup_path, alert: 'Please fill all fields correctly.'
        end
    end
    def resend_code
        
        if session[:pending_admin].present?
            code = session[:pending_admin]["code"]
            email = session[:pending_admin]["email"]
            AdminMailer.send_code(email, code).deliver_now
            redirect_to verify_code_path, notice: 'Code has been resent to your email.'
        else
            redirect_to signup_path, alert: 'Please start the signup process first.'
        end
    rescue => e
        redirect_to signup_path, alert: "Failed to resend code: #{e.message}" 
    end
    def verify_code
        unless session[:pending_admin].present?
            redirect_to signup_path, alert: 'Please start the signup process first.'
        end
    end
  
    def confirm_code
        entered_code = params[:code].strip
        if session[:pending_admin].present? 
            if session[:pending_admin]["code"].to_s == entered_code.to_s
                result = Admin.new!(name: session[:pending_admin]["name"], password: session[:pending_admin]["password"], email: session[:pending_admin]["email"])
                if result[:success]
                    session[:pending_admin] = nil
                    redirect_to login_path, notice: 'Admin was successfully created.'
                else
                    redirect_to verify_code_path, alert: result[:message]
                end
            else
                flash[:alert] = 'Invalid code. Please try again.' 
                redirect_to verify_code_path
            end
        else
            redirect_to signup_path, alert: 'Please start the signup process first.'
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

end
