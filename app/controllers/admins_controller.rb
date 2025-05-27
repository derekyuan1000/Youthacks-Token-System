class AdminsController < ApplicationController
    before_action :require_admin
    # before action :product_params, only: [:edit_product]
    def dashboard
        # @participants = if params[:query].present?
        #     Participant.where("name ILIKE ?", "%#{params[:query]}%")
        # else
        #     Participant.all
        # end
        @participants = Participant.active
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

    def earn
      participant = Participant.find(params[:id])
      amount = params[:amount].to_i if params[:amount].present? || 1 
      participant.earn!(amount, @admin.id) # or session[:admin_id]
      redirect_to dashboard_path, notice: "#{participant.name} just earned 1"
    end
    
    def buy
        participant = Participant.find(params[:id])
        product = Product.find(params[:product_id])
        result = participant.buy!(product, @admin.id) # or session[:admin_id]
        if result[:success]
            redirect_to dashboard_path, alert: "#{participant.name} just bought #{product.name}"
        else
            redirect_to dashboard_path, alert: result[:message]
        end
    end

    def delete_participant
        participant = Participant.find(params[:id])
        result = participant.delete!(@admin.id)
        
        if result[:success]
            redirect_to dashboard_path, alert: "#{participant.name} has been deleted"
        else
            redirect_to dashboard_path, alert: "Failed to delete #{participant.name}"
        end
    end

    def check_in_participant
        participant = Participant.find(params[:id])
        result = participant.check_in(@admin.id)
        if result[:success]
            redirect_to dashboard_path, alert: "#{participant.name} has been checked in"
        else
            redirect_to dashboard_path, alert: "Failed to check in #{participant.name}"
        end
    end
    private
    def require_admin
        unless session[:admin_id].present? and Admin.exists?(session[:admin_id])
            redirect_to login_path
            return  # <== STOP here to prevent further code running
        end

        @admin = Admin.find(session[:admin_id])
    end

end
