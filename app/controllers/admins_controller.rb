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

    def new
        return redirect_to login_path
    end

    def create
        name = params[:name]
        password = params[:password]
        password_confirmation = params[:password_confirmation]
        if name.present? && password.present? and password == password_confirmation
            result = Admin.new!(name: name, password: password, admin_id: @admin.id)
            if result[:success]
                redirect_to dashboard_path, notice: 'Admin was successfully created.'
            else
                redirect_to dashboard_path, alert: result[:message]
            end
        else
            redirect_to dashboard_path, alert: 'Failed to create admin. Please ensure all fields are filled out correctly.'
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
        puts "Name: #{name}", "Price: #{price}", "Description: #{description}", "Quantity: #{quantity}"
        Product.create(name: name, price: price, description: description, quantity: quantity, admin_id: @admin.id)
        redirect_to products_path, notice: 'Product was successfully created.'

    end
    def update_product
        product = Product.find(params[:id])
        name = params[:name]
        price = params[:price]
        description = params[:description]
        quantity = params[:quantity]
        puts "Product ID: #{product.id}", "Name: #{name}", "Price: #{price}", "Description: #{description}", "Quantity: #{quantity}"
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

    def transactions_refresh
        @transactions = Transaction.all
        render partial: "admins/transactions", locals: { transactions: @transactions }
    end

    
    private
    def require_admin
        unless session[:admin_id].present? and Admin.exists?(session[:admin_id])
            session[:admin_id] = nil  # Clear session if admin not found
            redirect_to login_path
            return  # <== STOP here to prevent further code running
        end

        @admin = Admin.find(session[:admin_id])
    end

end
