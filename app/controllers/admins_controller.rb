class AdminsController < ApplicationController
    before_action :require_admin
    def dashboard
        # @participants = if params[:query].present?
        #     Participant.where("name ILIKE ?", "%#{params[:query]}%")
        # else
        #     Participant.all
        # end
        @participants = Participant.all
        respond_to do |format|
            format.html # normal page load
            format.js   # AJAX request
        end
    end

    def set_balance
        participant = Participant.find( params[:id])
        # participant.set_balance(params[:balance]) # If you have a set_balance method in the model
        participant.set_balance!(params[:balance], @admin.id) # or just directly update
        redirect_to dashboard_path, notice: "Balance updated for #{participant.name}"
    end

    def bulk_earn
      # Example: params[:participant_ids] is an array of IDs from the checkboxes
      # params[:amount] is the quantity to earn
      participant_ids = params[:participant_ids] || []
      amount_to_earn  = params[:amount].to_i

      Participant.where(id: participant_ids).each do |p|
        p.earn!(amount_to_earn, @admin.id) # or session[:admin_id]
      end

      redirect_to dashboard_path, notice: "#{participant_ids.size} participants earned #{amount_to_earn}"
    end

    private

    def require_admin
        redirect_to login_path unless session[:admin_id].present?
        @admin = Admin.find(session[:admin_id])
    end
end
