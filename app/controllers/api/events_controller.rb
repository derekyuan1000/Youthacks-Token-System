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
        result = @event.sync
        if result[:success]
            render json: {participants: @event.participants.active}, status: :ok
        else
            render json: {message: result[:message] || "Failed to sync participants"}, status: :unprocessable_entity
        end
    end

    def set_balance
        participant = @event.participants.find(params[:participant_id])
        render json: { error: 'Participant not found' }, status: :not_found unless participant
        participant.set_balance!(params[:balance], @admin.id)
        render json: {participant: participant}
    end

    def earn
        participant = @event.participants.find(params[:participant_id])
        return render json: { error: 'Participant not found' }, status: :not_found unless participant
        amount = params[:amount].to_i if params[:amount].present? || 1 
        result = participant.earn!(amount: amount,admin_id: @admin.id)
        if result[:success]
            render json: {participant:participant}, status: :ok
        else
            render json: {message: result[:message]}, status: :unprocessable_entity
        end
    end

    def buy
        participant = @event.participants.find(params[:participant_id])
        return render json: { error: 'Participant not found' }, status: :not_found unless participant

        amount = params[:amount].to_i
        result = participant.buy!(params[:product_id], @admin.id)
        if result[:success]
            render json: { participant: participant, transaction: result[:transaction] }, status: :ok
        else
            render json: { message: result[:message] }, status: :unprocessable_entity
        end
    end

    def check_in_participant
        participant = @event.participants.find( params[:participant_id])
        return render json: { error: 'Participant not found' }, status: :not_found unless participant

        result = participant.check_in(@admin.id)
        if result[:success]
            render json: {participant: participant }, status: :ok
        else
            render json: { message: result[:message]}, status: :unprocessable_entity
        end
    end

    def delete_participant
        participant = @event.participants.find( params[:participant_id])
        return render json: { error: 'Participant not found' }, status: :not_found unless participant

        result = participant.delete!(@admin.id)
        if result[:success]
            render json: { participant: participant }, status: :ok
        else
            render json: { message: result[:message] }, status: :unprocessable_entity
        end
    end

    def products
        render json: @event.products
    end

    def create_product
        result = Product.create(name: params[:name],price: params[:price],description: params[:description],quantity: params[:quantity], admin_id: @admin.id, event_id: @event.id)
        if result[:success]
            render json: { product: result[:product] }, status: :created
        else
            render json: { message: result[:message] }, status: :unprocessable_entity
        end
    end

    def update_product
        product = @event.products.find_by(id: params[:id])
        return render json: { error: 'Product not found' }, status: :not_found unless product
        result = product.change!(name: params[:name], price: params[:price], description: params[:description], quantity: params[:quantity], admin_id: @admin.id)
        if result[:success]
            render json: {product: product}
        else
            render json: { error: result[:message]}, status: :unprocessable_entity
        end
    end
    

    def delete_product
      product = @event.products.find_by(id: params[:id])
      return render json: { error: 'Product not found' }, status: :not_found unless product

      result = product.delete!(admin_id: @admin.id)
      if result[:success]
          render json: { product: product }
      else
          render json: { message: result[:message] }, status: :unprocessable_entity
      end
    end

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
