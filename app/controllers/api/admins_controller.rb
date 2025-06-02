class Api::AdminsController < Api::BaseController
    before_action :require_admin, except: [:create]

    def create
        admin_params = params.require(:admin).permit(:name, :email, :password)
        result = Admin.new!(admin_params)

        if result[:success]
            @admin = Admin.find_by(admin_params[:name])
            render json: @admin, status: :created
        else
            render json: result[:message], status: :unprocessable_entity
        end
    end


    def pending_invitations
        invitations = @admin.invitations.pending
        render json: invitations, status: :ok
    end

    def accept_invitation
        invitation = @admin.invitations.pending.find(params[:invitation_id])
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
    rescue StandardError => e
        render json: { error: e.message }, status: :internal_server_error
    end

end
