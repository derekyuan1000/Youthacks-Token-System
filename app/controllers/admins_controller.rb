class AdminsController < ApplicationController
    before_action :require_admin
    def dashboard
        return redirect_to login_path unless session[:admin_id].present?
        @admin = Admin.find(session[:admin_id])
        @participants = if params[:query].present?
            Participant.where(
                "CAST(participant_id AS TEXT) LIKE :query OR name LIKE :query OR email LIKE :query",
                query: "%#{params[:query]}%"
            )
        else
            Participant.all
        end
    end

    def set_balance
        participant = Participant.find( params[:id])
        # participant.set_balance(params[:balance]) # If you have a set_balance method in the model
        participant.set_balance!(params[:balance], @admin.id) # or just directly update
        redirect_to dashboard_path, notice: "Balance updated for #{participant.name}"
    end

    private

    def require_admin
        redirect_to login_path unless session[:admin_id].present?
        @admin = Admin.find(session[:admin_id])
    end
end
