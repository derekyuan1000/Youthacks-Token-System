class AdminsController < ApplicationController
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
end
