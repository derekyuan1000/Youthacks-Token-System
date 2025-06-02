class Api::AdminsController < Api::BaseController
    before_action :require_admin, except: [:create, :resend_code, :confirm_code]
    rescue_from StandardError, with: :handle_error
    def create
        admin_params = params.permit(:name, :email, :password)
        name = admin_params[:name]
        password = admin_params[:password]
        email = admin_params[:email]

        if name.present? && password.present? && email.present?
            code = rand(100_000..999_999)
            AdminMailer.send_code(email, code).deliver_now

            pending_token = JWT.encode ({
                name: name,
                email: email,
                password: password,
                code: code,
                exp: 30.minutes.from_now.to_i
            }, Rails.application.secret_key_base)
            render json: { message: 'Verification code sent', token: pending_token}, status: :created
        else
            render json: { error: 'Name, password, and email cannot be blank' }, status: :unprocessable_entity
        end
    end

    def forgot_password
        render json: { message: 'Password reset not implemented' }, status: :not_implemented
    end

    def resend_code
        header = request.headers['Authorization']
        token = header&.split(' ')&.last

        if token.blank?
            render json: { error: 'Missing token' }, status: :unauthorized
            return
        end

        begin
            decoded = JWT.decode(token, Rails.application.secret_key_base)[0]
            email = decoded['email']
            code = decoded['code']
            AdminMailer.send_code(email, code).deliver_now
            render json: { message: 'Code resent successfully' }, status: :ok
        rescue JWT::DecodeError
            render json: { error: 'Invalid token' }, status: :unauthorized
        end
    end

    def confirm_code   
        header = request.headers['Authorization']
        token = header&.split(' ')&.last

        if token.blank?
            render json: { error: 'Missing token' }, status: :unauthorized
            return
        end

        begin
            decoded = JWT.decode(token, Rails.application.secret_key_base)[0]
            entered_code = params[:code].strip
            if decoded['code'].to_s == entered_code.to_s
                result = Admin.new!(name: decoded['name'], password: decoded['password'], email: decoded['email'])
                if result[:success]
                    render json: { message: 'Admin created successfully', admin: result[:admin] }, status: :created
                else
                    render json: { error: result[:message] }, status: :unprocessable_entity
                end
            else
                render json: { error: 'Invalid code' }, status: :invalid
            end
        rescue JWT::DecodeError => e
            render json: { error: 'Invalid token' }, status: :unauthorized
        end
    end

    def pending_invitations
        invitations = @admin.invitations.pending
        render json: invitations, status: :ok
    end

    def accept_invitation
        invitation = @admin.invitations.pending.find_by(id: params[:invitation_id])
        if invitation
            result = invitation.accept![:success]
            if result[:success]
                render json: { message: 'Invitation accepted' }, status: :ok
            else
                render json: { error: result[:message] || 'Failed to accept invitation' }, status: :unprocessable_entity
            end
        else
            render json: { error: 'Invitation not found' }, status: :not_found
        end
    end

    def reject_invitation
        invitation = @admin.invitations.pending.find(params[:invitation_id])
        if invitation
            invitation.reject!
            render json: { message: 'Invitation rejected' }, status: :ok
        else
            render json: { error: 'Invitation not found or already processed' }, status: :not_found
        end
    end

    def create_event
        event_params = params.require(:event).permit(name:, description: "", date:, manager_id:, sync_with_airtable:false)
        result = @admin.events.create!(event_params, manager_id: @admin.id)
        if result[:success]
            render json: result[:event], status: :created
        else
            render json: result[:message], status: :unprocessable_entity
        end
    end

    def events
        events = @admin.events + @admin.managed_events
        render json: events, status: :ok
    rescue StandardError => e
        render json: { error: e.message }, status: :internal_server_error
    end

    def settings
        render json: { admin: @admin }, status: :ok
    end

    private

    def require_admin
        header = request.headers['Authorization']
        token = header&.split(' ')&.last

        if token.blank?
            render json: { error: 'Missing token' }, status: :unauthorized
            return
        end

        begin
            decoded = JWT.decode(token, Rails.application.secret_key_base)[0]
            @admin = Admin.find(decoded['user_id'])
        rescue JWT::ExpiredSignature
            render json: { error: 'Token expired' }, status: :unauthorized
        rescue JWT::DecodeError
            render json: { error: 'Invalid token' }, status: :unauthorized
        rescue ActiveRecord::RecordNotFound
            render json: { error: 'Admin not found' }, status: :unauthorized
        end

    end

end
