class AdminsController < ApplicationController
    before_action :require_admin, except: [:new, :create, :verify_code, :confirm_code, :resend_code]

    def new
        # Render the signup form
        if session[:admin_id].present?
            redirect_to dashboard_path, notice: "You are already logged in."
        else
            @admin = Admin.new
        end
    end
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

    def sync_participants
        begin
            Participant.sync
            @participants = Participant.active
            redirect_to dashboard_path, notice: "Participants synced successfully"
        rescue => e
            redirect_to dashboard_path, alert: "Failed to sync participants: #{e.message}"
        end
    end
    def activity
        @activities = Activity.all
        respond_to do |format|
            format.html # normal page load
            format.js   # AJAX request
        end
    end

    def transactions
        @transactions = Transaction.all
        respond_to do |format|
            format.html # normal page load
            format.js   # AJAX request
        end
    end

    def settings
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
      participant.earn!(amount: amount,admin_id: @admin.id) # or session[:admin_id]
      redirect_to dashboard_path, notice: "#{participant.name} just earned 1"
    end
    
    def buy
        participant = Participant.find(params[:id])
        product = Product.find(params[:product_id])
        result = participant.buy!(product, @admin.id) # or session[:admin_id]
        if result[:success]
            redirect_to dashboard_path, notice: "#{participant.name} just bought #{product.name}"
        else
            redirect_to dashboard_path, alert: result[:message]
        end
    end

    def delete_participant
        participant = Participant.find(params[:id])
        result = participant.delete!(@admin.id)
        
        if result[:success]
            redirect_to dashboard_path, notice: "#{participant.name} has been deleted"
        else
            redirect_to dashboard_path, alert: "Failed to delete #{participant.name}"
        end
    end

    def check_in_participant
        participant = Participant.find(params[:id])
        result = participant.check_in(@admin.id)
        if result[:success]
            redirect_to dashboard_path, notice: "#{participant.name} has been checked in"
        else
            redirect_to dashboard_path, alert: "Failed to check in #{participant.name}"
        end
    end
    def create_product
        name = params[:name]
        price = params[:price]
        description = params[:description]
        quantity = params[:quantity]
        Product.create(name: name, price: price, description: description, quantity: quantity, admin_id: @admin.id)
        redirect_to products_path, notice: 'Product was successfully created.'

    end
    def update_product
        product = Product.find(params[:id])
        name = params[:name]
        price = params[:price]
        description = params[:description]
        quantity = params[:quantity]
        result = product.change!(name: name, price: price, description: description, quantity: quantity, admin_id: @admin.id)
        if result[:success]
            redirect_to products_path, notice: 'Product was successfully updated.'
        else
            redirect_to products_path, alert: result[:message] || 'Failed to update product.'
        end
    end
    def delete_product
        product = Product.find(params[:id])
        result = product.delete!(admin_id:@admin.id) # or session[:admin_id]
        if result[:success]
            redirect_to products_path, notice: 'Product was successfully deleted.'
        else
            redirect_to products_path, alert: 'Failed to delete product.'
        end
    end
    def activity_refresh
        @activities = Activity.all
        render partial: "admins/activity", locals: { activities: @activities }
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
            begin
                Rails.logger.info "Sending email to #{email}..."
                AdminMailer.send_code(email, code).deliver_now
                Rails.logger.info "Email sent successfully"
            rescue => e
                Rails.logger.error "Email failed to send: #{e.message}"
            end
            redirect_to verify_code_path, notice: 'Code has been resent to your email.'
        else
            redirect_to signup_path, alert: 'Please start the signup process first.'
        end
    end
    def verify_code
        unless session[:pending_admin].present?
            redirect_to signup_path, alert: 'Please start the signup process first.'
        # Form for user to enter the code
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
