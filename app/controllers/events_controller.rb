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
        @participants = Participant.active
        respond_to do |format|
            format.html # normal page load
            format.js   # AJAX request
        end
    end

    def settings
    end

    def sync_participants
        begin
            unless @event.airtable_api_key.present? and @event.airtable_base_id.present? and @event.airtable_table_name.present?
                raise "Airtable API key, base ID, and table name must be set for this event"
            end
            result = @event.sync
            if result[:success]
                @participants = Participant.active
                redirect_to event_dashboard_path, notice: "Participants synced successfully"
            else
                raise result[:message] || "Failed to sync participants"
            end
        rescue => e
            redirect_to event_dashboard_path, alert: "Failed to sync participants: #{e.message}"
        end
    end

    def activity
        @activities = Activity.all

    end

    


    def transactions
        @transactions = Transaction.all
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
        Product.create(name: name, price: price, description: description, quantity: quantity, admin_id: @admin.id, event_id: @event.id)
        redirect_to event_products_path, notice: 'Product was successfully created.'

    end
    def update_product
        product = Product.find(params[:id])
        name = params[:name]
        price = params[:price]
        description = params[:description]
        quantity = params[:quantity]
        result = product.change!(name: name, price: price, description: description, quantity: quantity, admin_id: @admin.id, event_id: @event.id)
        if result[:success]
            redirect_to event_products_path, notice: 'Product was successfully updated.'
        else
            redirect_to event_products_path, alert: result[:message] || 'Failed to update product.'
        end
    end
    def delete_product
        product = Product.find(params[:id])
        result = product.delete!(admin_id:@admin.id) # or session[:admin_id]
        if result[:success]
            redirect_to event_products_path, notice: 'Product was successfully deleted.'
        else
            redirect_to event_products_path, alert: 'Failed to delete product.'
        end
    end
    
    def activity_refresh
        @activities = Activity.all
        render partial: "events/activity", locals: { activities: @activities }
    end

    def transactions_refresh
        @transactions = Transaction.all
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
