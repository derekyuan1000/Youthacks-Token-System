class Api::EventsController < Api::AdminsController
    before_action :require_event

    def participants
      render json: {participants: @event.participants}
    end

    def create_participant
        params = params.permit(:name)
        if @event.sync_with_airtable
            result = @event.create_to_airtable!(name: params[:name], admin_id: @admin.id)
        else
            result = @event.create_without_airtable!(name: params[:name], admin_id: @admin.id)
        if result[:success]
            render json: {participant: result[:participant]}, status: :created
        else
            render json: {message: result[:message] }, status: :unprocessable_entity
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

    # POST /participants/:id/set_balance
    def set_balance
      participant = @event.participants.find_by(id: params[:id])
      return render json: { error: 'Participant not found' }, status: :not_found unless participant

      balance = params[:balance].to_i
      participant.update(balance: balance)
      render json: participant
    end

    # POST /participants/bulk_earn
    def bulk_earn
      ids = params[:ids] || []
      amount = params[:amount].to_i
      participants = @event.participants.where(id: ids)
      participants.update_all("balance = balance + #{amount}")
      render json: participants
    end

    # POST /participants/:id/earn
    def earn
      participant = @event.participants.find_by(id: params[:id])
      return render json: { error: 'Participant not found' }, status: :not_found unless participant

      amount = params[:amount].to_i
      participant.increment!(:balance, amount)
      render json: participant
    end

    # POST /participants/:id/buy
    def buy
      participant = @event.participants.find_by(id: params[:id])
      return render json: { error: 'Participant not found' }, status: :not_found unless participant

      amount = params[:amount].to_i
      if participant.balance >= amount
        participant.decrement!(:balance, amount)
        render json: { message: 'Purchase successful' }
      else
        render json: { error: 'Insufficient balance' }, status: :unprocessable_entity
      end
    end

    # POST /participants/:id/check_in
    def check_in_participant
      participant = @event.participants.find_by(id: params[:id])
      return render json: { error: 'Participant not found' }, status: :not_found unless participant

      participant.update(checked_in: true)
      render json: participant
    end

    # POST /participants/bulk_check_in
    def bulk_check_in
      ids = params[:ids] || []
      participants = @event.participants.where(id: ids)
      participants.update_all(checked_in: true)
      render json: participants
    end

    # DELETE /participants/:id
    def delete_participant
      participant = @event.participants.find_by(id: params[:id])
      return render json: { error: 'Participant not found' }, status: :not_found unless participant

      participant.destroy
      render json: { message: 'Participant deleted' }
    end

    # GET /products
    def products
      render json: @event.products
    end

    # POST /products/create
    def create_product
      product = @event.products.create(product_params)
      if product.persisted?
        render json: product, status: :created
      else
        render json: { error: product.errors.full_messages }, status: :unprocessable_entity
      end
    end

    # POST /products/:id/edit
    def update_product
      product = @event.products.find_by(id: params[:id])
      return render json: { error: 'Product not found' }, status: :not_found unless product

      if product.update(product_params)
        render json: product
      else
        render json: { error: product.errors.full_messages }, status: :unprocessable_entity
      end
    end

    # DELETE /products/:id
    def delete_product
      product = @event.products.find_by(id: params[:id])
      return render json: { error: 'Product not found' }, status: :not_found unless product

      product.destroy
      render json: { message: 'Product deleted' }
    end

    # GET /activity
    def activity
      render json: @event.activities.order(created_at: :desc)
    end

    # GET /transactions
    def transactions
      render json: @event.transactions.order(created_at: :desc)
    end

    private

    def require_event
        event = params[:event_id]
        if event.blank?
            render json: { error: 'Event ID is required' }, status: :bad_request
        else
            @event = Event.find_by(id: event)
            if @event.nil?
                render json: { error: 'Event not found' }, status: :not_found
            elsif @event.admins.exclude?(@admin) or @event.manager.id != @admin.id
                render json: { error: 'Unauthorized access to event' }, status: :forbidden
            end
        end
    end

end
