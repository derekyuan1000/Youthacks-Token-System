module API
  class Events < Admins
    before do
      require_event!
    end

    resource :events do
      route_param :event_slug, type: String do
        get 'participants' do
          present participants: @event.participants.active, with API::Entities::Participant
        end

        params do
          requires :name, type: String
        end
        post 'participants' do
          if @event.sync_with_airtable
            result = @event.create_to_airtable!(name: params[:name], admin_id: @admin.id)
          else
            result = @event.create_without_airtable!(name: params[:name], admin_id: @admin.id)
          end
          if result[:success]
            status :created
            present participant: result[:participant], with: API::Entities::Participant::Public
          else
            error!({ message: result[:message] }, 422)
          end
        end

        post 'sync_participants' do
          result = @event.sync
          if result[:success]
            status :ok
            present participants: @event.participants.active, with: API::Entities::Participant::Public
          else
            error!({ message: result[:message] || "Failed to sync participants" }, 422)
          end
        end

        params do
          requires :participant_id, type: Integer
          requires :balance, type: Integer
        end
        post 'participants/:participant_id/set_balance' do
          participant = @event.participants.find_by(id: params[:participant_id])
          error!({ error: 'Participant not found' }, 404) unless participant
          participant.set_balance!(params[:balance], @admin.id)
          present participant: participant, with: API::Entities::Participant::Public
        end

        params do
          requires :participant_id, type: Integer
          optional :amount, type: Integer, default: 1
        end
        post 'participants/:participant_id/earn' do
          participant = @event.participants.find_by(id: params[:participant_id])
          error!({ error: 'Participant not found' }, 404) unless participant
          amount = params[:amount] || 1
          result = participant.earn!(amount: amount, admin_id: @admin.id)
          if result[:success]
            status :ok
            present participant: participant, with: API::Entities::Participant::Public
          else
            error!({ message: result[:message] }, 422)
          end
        end

        params do
          requires :participant_id, type: Integer
          requires :amount, type: Integer
          requires :product_id, type: Integer
        end
        post 'participants/:participant_id/buy' do
          participant = @event.participants.find_by(id: params[:participant_id])
          error!({ error: 'Participant not found' }, 404) unless participant
          result = participant.buy!(params[:product_id], @admin.id)
          if result[:success]
            status :ok
            present transaction: result[:transaction], with: API::Entities::Transaction
          else
            error!({ message: result[:message] }, 422)
          end
        end

        params do
          requires :participant_id, type: Integer
        end
        post 'participants/:participant_id/check_in' do
          participant = @event.participants.find_by(id: params[:participant_id])
          error!({ message: 'Participant not found' }, 404) unless participant
          result = participant.check_in(@admin.id)
          if result[:success]
            status :ok
            present participant: participant, with: API::Entities::Participant::Public
          else
            error!({ message: result[:message] }, 422)
          end
        end

        params do
          requires :participant_id, type: Integer
        end
        delete 'participants/:participant_id' do
          participant = @event.participants.find_by(id: params[:participant_id])
          error!({ error: 'Participant not found' }, 404) unless participant
          result = participant.delete!(@admin.id)
          if result[:success]
            status :ok
            present participant: participant, with: API::Entities::Participant::Public
          else
            error!({ message: result[:message] }, 422)
          end
        end

        get 'products' do
          present @event.products.active, with: API::Entities::Product
        end

        params do
          requires :name, type: String
          requires :price, type: Numeric
          optional :description, type: String
          optional :quantity, type: Integer
        end
        post 'products' do
          result = Product.create(name: params[:name], price: params[:price], description: params[:description], quantity: params[:quantity], admin_id: @admin.id, event_slug: @event.id)
          if result[:success]
            status :created
            present product: result[:product], with: API::Entities::Product
          else
            error!({ message: result[:message] }, 422)
          end
        end

        params do
          requires :id, type: Integer
          optional :name, type: String
          optional :price, type: Numeric
          optional :description, type: String
          optional :quantity, type: Integer
        end
        put 'products/:id' do
          product = @event.products.find_by(id: params[:id])
          error!({ error: 'Product not found' }, 404) unless product
          result = product.change!(name: params[:name], price: params[:price], description: params[:description], quantity: params[:quantity], admin_id: @admin.id)
          if result[:success]
            present product: product, with: API::Entities::Product
          else
            error!({ message: result[:message] }, 422)
          end
        end

        params do
          requires :id, type: Integer
        end
        delete 'products/:id' do
          product = @event.products.find_by(id: params[:id])
          error!({ error: 'Product not found' }, 404) unless product
          result = product.delete!(admin_id: @admin.id)
          if result[:success]
            status :ok
            present product: product
          else
            error!({ message: result[:message] }, 422)
          end
        end

        get 'activity' do
          present @event.activities.order(created_at: :desc), with: API::Entities::Activity
        end

        get 'transactions' do
          present @event.transactions.order(created_at: :desc), with: API::Entities::Transaction
        end
      end

      helpers do
        def require_event!
          event = params[:event_slug]
          error!({ error: 'Event ID is required' }, 400) if event.blank?

          @event = Event.find_by(id: event)
          error!({ message: 'Event not found' }, 404) if @event.nil?
          if @event.admins.exclude?(@admin) || @event.manager.id != @admin.id
            error!({ message: 'Unauthorized access to event' }, 403)
          end
        end
      end
    end
  end
end
