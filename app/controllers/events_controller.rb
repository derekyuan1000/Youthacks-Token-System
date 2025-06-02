class EventsController < AdminsController
    before_action :require_event
    before_action :require_access

    def new
    end

    def dashboard
        # @participants = if params[:query].present?
        #     Participant.where("name ILIKE ?", "%#{params[:query]}%")
        # else
        #     Participant.all
        # end
        @participants = @event.participants.active
        respond_to do |format|
            format.html # normal page load
            format.js   # AJAX request
        end
    end

    def create_participant
        name = params[:name].strip
        if @event.sync_with_airtable
            result = @event.create_to_airtable!(name: name, admin_id: @admin.id) # or session[:admin_id]
        else
            result = @event.create_without_airtable!(name: name, admin_id: @admin.id) # or session[:admin_id]
        end
        if result[:success]
            redirect_to event_dashboard_path, notice: "#{name} has been created as a participant."
        else
            redirect_to event_dashboard_path, alert: result[:message] || "Failed to create participant."
        end
    end


    def sync_participants
        begin
            result = @event.sync
            if result[:success]
                @participants = @event.participants.active
                redirect_to event_dashboard_path, notice: "Participants synced successfully. Any activity of participants deleted will be listed as under the manager."
            else
                raise result[:message] || "Failed to sync participants"
            end
        rescue => e
            redirect_to event_dashboard_path, alert: "Failed to sync participants: #{e.message}"
        end
    end

    def activity
        @activities = @event.activities.all

    end

    


    def transactions
        @transactions = @event.transactions.all
    end

    def settings
    end

    def set_balance
        participant = @event.participants.find( params[:id])
        redirect_to event_dashboard_path, alert: "Participant not found." and return unless participant
        # participant.set_balance(params[:balance]) # If you have a set_balance method in the model
        participant.set_balance!(params[:balance], @admin.id) # or just directly update
        redirect_to event_dashboard_path, notice: "Balance updated for #{participant.name}"
    end

    def bulk_earn
      # Example: params[:participant_ids] is an array of IDs from the checkboxes
      # params[:amount] is the quantity to earn
      participant_ids = params[:participant_ids] || []
      amount_to_earn  = params[:amount].to_i

      Participant.where(id: participant_ids).each do |p|
        p.earn!(amount: amount_to_earn,admin_id: @admin.id) # or session[:admin_id]
      end

      redirect_to event_dashboard_path, notice: "#{participant_ids.size} participants earned #{amount_to_earn} token"

    end

    def bulk_check_in
        participant_ids = params[:participant_ids] || []
        Participant.where(id: participant_ids).each do |p|
            result = p.check_in(@admin.id)
            if result[:success]
                flash[:notice] ||= []
                flash[:notice] << "#{p.name} has been checked in"
            else
                flash[:alert] ||= []
                flash[:alert] << "Failed to check in #{p.name}: #{result[:message]}"
            end
        end
        if flash[:notice].present? and flash[:alert].present?
            redirect_to event_dashboard_path, notice: flash[:notice].join(", "), alert: flash[:alert].join(", ")
        elsif flash[:notice].present? and flash[:alert].blank?
            flash[:notice] = flash[:notice].join(", ")
            redirect_to event_dashboard_path, notice: flash[:notice]
        elsif flash[:alert].present? and flash[:notice].blank?
            flash[:alert] = flash[:alert].join(", ")
            redirect_to event_dashboard_path, alert: flash[:alert]
        else
            redirect_to event_dashboard_path, alert: "No participants were checked in. Something went wrong."
        end 
    end
    def earn
        participant = @event.participants.find(params[:id])
        amount = params[:amount].to_i if params[:amount].present? || 1 
        result = participant.earn!(amount: amount,admin_id: @admin.id) # or session[:admin_id]
        if result[:success]
            redirect_to event_dashboard_path, notice: "#{participant.name} just earned #{amount} token"
        else
            redirect_to event_dashboard_path, alert: result[:message] || "Failed to earn tokens for #{participant.name}"
        end
    end
    def buy
        participant = @event.participants.find(params[:id])
        product = @event.products.find(params[:product_id])
        result = participant.buy!(product, @admin.id) # or session[:admin_id]
        if result[:success]
            redirect_to event_dashboard_path, notice: "#{participant.name} just bought #{product.name}"
        else
            redirect_to event_dashboard_path, alert: result[:message]
        end
    end

    def delete_participant
        participant = @event.participants.find(params[:id])
        result = participant.delete!(@admin.id)
        
        if result[:success]
            redirect_to event_dashboard_path, notice: "#{participant.name} has been deleted"
        else
            redirect_to event_dashboard_path, alert: "Failed to delete #{participant.name}"
        end
    end

    def check_in_participant
        participant = @event.participants.find(params[:id])
        result = participant.check_in(@admin.id)
        if result[:success]
            redirect_to event_dashboard_path, notice: "#{participant.name} has been checked in"
        else
            redirect_to event_dashboard_path, alert: "Failed to check in #{participant.name}"
        end
    end
    def create_product
        name = params[:name]
        price = params[:price]
        description = params[:description]
        quantity = params[:quantity]
        Product.create(name: name, price: price, description: description, quantity: quantity, admin_id: @admin.id, event_id: @event.id)
        redirect_to event_products_path, notice: 'Product was successfully created.'

    end
    def update_product
        product = @event.products.find(params[:id])
        name = params[:name]
        price = params[:price]
        description = params[:description]
        quantity = params[:quantity]
        result = product.change!(name: name, price: price, description: description, quantity: quantity, admin_id: @admin.id)
        if result[:success]
            redirect_to event_products_path, notice: 'Product was successfully updated.'
        else
            redirect_to event_products_path, alert: result[:message] || 'Failed to update product.'
        end
    end
    def delete_product
        product = @event.products.find(params[:id])
        result = product.delete!(admin_id:@admin.id) # or session[:admin_id]
        if result[:success]
            redirect_to event_products_path, notice: 'Product was successfully deleted.'
        else
            redirect_to event_products_path, alert: 'Failed to delete product.'
        end
    end
    
    def activity_refresh
        @activities = @event.activities.all
        render partial: "events/activity", locals: { activities: @activities }
    end

    def transactions_refresh
        @transactions = @event.transactions.all
        render partial: "events/transactions", locals: { transactions: @transactions }
    end
    def create
    end

    private

    def require_event
        begin 
            event = Event.friendly.find(params[:event_slug])
            unless event.present?
                redirect_to dashboard_path, alert: "Event not found."
                return
            else
                @event = event
            end
        rescue => e
            redirect_to dashboard_path, alert: "Event does not exist."
        end
    end

    def require_access
        begin 
            unless @event.admins.exists?(@admin.id) or @event.manager_id == @admin.id
                redirect_to dashboard_path, alert: "Event does not exist."
            end
        rescue => e
            redirect_to dashboard_path, alert: "Event does not exist."
        end
    end
end
