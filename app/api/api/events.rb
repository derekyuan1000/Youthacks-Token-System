module Api
	class Events < Grape::API

		AUTH_HEADER_DOC = {
			Authorization: {
				required: true,
				type: 'string',
				description: ' token for admin authentication'
			}
		}.freeze

		helpers do
			def require_admin!
				header = headers['Authorization']
				token = header&.split(' ')&.last

				error!({ message: 'Missing token' }, 401) if token.blank?

				begin
					decoded = JWT.decode(token, Rails.application.secret_key_base)[0]
					error!({message: 'Invalid token type' }, 401) unless decoded['type'] == 'login'
					@admin = Admin.find(decoded['user_id'])
				rescue JWT::ExpiredSignature
					error!({ message: 'Token expired' }, 401)
				rescue JWT::DecodeError
					error!({ message: 'Invalid token' }, 401)
				rescue ActiveRecord::RecordNotFound
					error!({ message: 'Admin not found' }, 401)
				end
			end
			def require_event!(event_slug:)
				
				error!({ message: 'Event ID is required' }, 400) if event_slug.blank?

				@event = Event.find_by(slug: event_slug)
				error!({ message: 'Event not found' }, 404) if @event.nil?

				unless @event.admins.include?(@admin) || @event.manager.id == @admin.id
					error!({ message: 'Unauthorized access to event' }, 403)
				end
			end
		end

		
		desc 'Event scoped routes' do
			summary 'Routes that operate on a specific event identified by event_slug'
			detail 'Provides operations on participants, products, transactions, and activities scoped under a particular event'
			tags ['Events']
			failure [[400, 'Event ID is required', Api::Entities::Error], [403, 'Unauthorized access to event', Api::Entities::Error], [404, 'Event not found', Api::Entities::Error]]
		end

		resource :events do
			route_param :event_slug, type: String do
		
				before do
					require_admin!
					require_event!(event_slug: params[:event_slug])
				end

				desc 'Get participants for an event' do
					summary 'Get participants for an event'
					detail 'Returns a list of active participants for the specified event'
					tags ['Events']
					is_array true
					success Api::Entities::Participant::Full
					failure [[401, 'Unauthorized', Api::Entities::Error], [404, 'Event not found', Api::Entities::Error]] 
					headers AUTH_HEADER_DOC
				end
				params do
				end
				get 'participants' do
					present @event.participants.active, with: Api::Entities::Participant::Full
				end

				desc 'Add a participant to an event' do
					summary 'Add a participant to an event'
					detail 'Creates a new participant in the event'
					tags ['Events']
					success Api::Entities::Participant::Public
					failure [[401, 'Unauthorized', Api::Entities::Error], [422, 'Unprocessable Entity', Api::Entities::Error]]
					headers AUTH_HEADER_DOC
				end
				params do
					requires :name, type: String, documentation: { hidden: true }
				end
				post 'participants' do
					if @event.sync_with_airtable
						result = @event.create_to_airtable!(name: params[:name], admin_id: @admin.id)
					else
						result = @event.create_without_airtable!(name: params[:name], admin_id: @admin.id)
					end
					if result[:success]
						status :created
						present participant: result[:participant], with: Api::Entities::Participant::Public
					else
						error!({ message: result[:message] }, 422)
					end
				end

				desc 'Sync participants for an event' do
					summary 'Sync participants for an event'
					detail 'Synchronizes participants data for the event'
					tags ['Events']
					is_array true
					success Api::Entities::Participant::Public
					failure [[401, 'Unauthorized', Api::Entities::Error], [422, 'Unprocessable Entity', Api::Entities::Error]]
					headers AUTH_HEADER_DOC
				end
				params do
				end
				post 'sync_participants' do
					result = @event.sync
					if result[:success]
						status :ok
						present participants: @event.participants.active, with: Api::Entities::Participant::Public
					else
						error!({ code:422,message: result[:message] || "Failed to sync participants" }, 422)
					end
				end

				desc 'Set participant balance' do
					summary 'Set participant balance'
					detail 'Sets the balance for a participant in the event'
					tags ['Events']
					success Api::Entities::Participant::Public
					failure [[401, 'Unauthorized', Api::Entities::Error], [404, 'Participant not found', Api::Entities::Error]]
					headers AUTH_HEADER_DOC
				end
				params do
					requires :participant_id, type: Integer, documentation: { hidden: true }
					requires :balance, type: Integer, documentation: { hidden: true }
				end
				post 'participants/:participant_id/set_balance' do
					participant = @event.participants.find_by(id: params[:participant_id])
					error!({code:404, message: 'Participant not found' }, 404) unless participant
					participant.set_balance!(balance: params[:balance],admin_id: @admin.id)
					present participant: participant, with: Api::Entities::Participant::Public
				end

				desc 'Earn points for participant' do
					summary 'Earn points for participant'
					detail 'Adds points to a participant\'s balance'
					tags ['Events']
					success Api::Entities::Participant::Public
					failure [[401, 'Unauthorized', Api::Entities::Error], [404, 'Participant not found', Api::Entities::Error], [422, 'Unprocessable Entity', Api::Entities::Error]]
					headers AUTH_HEADER_DOC
				end
				params do
					requires :participant_id, type: Integer, documentation: { hidden: true }
					optional :amount, type: Integer, default: 1, documentation: { hidden: true }
				end
				post 'participants/:participant_id/earn' do
					participant = @event.participants.find_by(id: params[:participant_id])
					error!({ message: 'Participant not found' }, 404) unless participant
					amount = params[:amount] || 1
					result = participant.earn!(amount: amount, admin_id: @admin.id)
					if result[:success]
						status :ok
						present participant: participant, with: Api::Entities::Participant::Public
					else
						error!({ message: result[:message] }, 422)
					end
				end

				desc 'Participant buys a product' do
					summary 'Participant buys a product'
					detail 'Processes a purchase transaction for a participant'
					tags ['Events']
					success Api::Entities::Transaction
					failure [[401, 'Unauthorized', Api::Entities::Error], [404, 'Participant not found', Api::Entities::Error], [422, 'Unprocessable Entity', Api::Entities::Error]]
					headers AUTH_HEADER_DOC
				end
				params do
					requires :participant_id, type: Integer, documentation: { hidden: true }
					requires :product_id, type: Integer, documentation: { hidden: true }
				end
				post 'participants/:participant_id/buy/:product_id' do
					participant = @event.participants.find_by(id: params[:participant_id])
					error!({ message: 'Participant not found' }, 404) unless participant
					result = participant.buy!(params[:product_id], @admin.id)
					if result[:success]
						status :ok
						present transaction: result[:transaction], with: Api::Entities::Transaction
					else
						error!({ message: result[:message] }, 422)
					end
				end

				desc 'Check in a participant' do
					summary 'Check in a participant'
					detail 'Checks in a participant to the event'
					tags ['Events']
					success Api::Entities::Participant::Public
					failure [[401, 'Unauthorized', Api::Entities::Error], [404, 'Participant not found', Api::Entities::Error], [422, 'Unprocessable Entity', Api::Entities::Error]]
					headers AUTH_HEADER_DOC
				end
				params do
					requires :participant_id, type: Integer, documentation: { hidden: true }
				end
				post 'participants/:participant_id/check_in' do
					participant = @event.participants.find_by(id: params[:participant_id])
					error!({ message: 'Participant not found' }, 404) unless participant
					result = participant.check_in(@admin.id)
					if result[:success]
						status :ok
						present participant: participant, with: Api::Entities::Participant::Public
					else
						error!({ message: result[:message] }, 422)
					end
				end

				desc 'Delete a participant' do
					summary 'Delete a participant'
					detail 'Deletes a participant from the event'
					tags ['Events']
					success Api::Entities::Participant::Public
					failure [[401, 'Unauthorized', Api::Entities::Error], [404, 'Participant not found', Api::Entities::Error], [422, 'Unprocessable Entity', Api::Entities::Error]]
					headers AUTH_HEADER_DOC
				end
				params do
					requires :participant_id, type: Integer
				end
				delete 'participants/:participant_id' do
					participant = @event.participants.find_by(id: params[:participant_id])
					error!({ message: 'Participant not found' }, 404) unless participant
					result = participant.delete!(@admin.id)
					if result[:success]
						status :ok
						present participant: participant, with: Api::Entities::Participant::Public
					else
						error!({ message: result[:message] }, 422)
					end
				end

				desc 'Get products for an event' do
					summary 'Get products for an event'
					detail 'Returns a list of active products for the event'
					tags ['Events']
					success Api::Entities::Product
					failure [[401, 'Unauthorized', Api::Entities::Error], [404, 'Event not found', Api::Entities::Error]]
					headers AUTH_HEADER_DOC
				end
				params do
				end
				get 'products' do
					present @event.products.active, with: Api::Entities::Product
				end

				desc 'Create a product for an event' do
					summary 'Create a product for an event'
					detail 'Creates a new product for the event'
					tags ['Events']
					success Api::Entities::Product
					failure [[401, 'Unauthorized', Api::Entities::Error], [422, 'Unprocessable Entity', Api::Entities::Error]]
					headers AUTH_HEADER_DOC
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
						present product: result[:product], with: Api::Entities::Product
					else
						error!({ message: result[:message] }, 422)
					end
				end

				desc 'Update a product' do
					summary 'Update a product'
					detail 'Updates details of a product'
					tags ['Events']
					success Api::Entities::Product
					failure [[401, 'Unauthorized', Api::Entities::Error], [404, 'Product not found', Api::Entities::Error], [422, 'Unprocessable Entity', Api::Entities::Error]]
					headers AUTH_HEADER_DOC
				end
				params do
					requires :id, type: Integer
					optional :name, type: String
					optional :price, type: Numeric
					optional :description, type: String
					optional :quantity, type: Integer
				end
				patch 'products/:id' do
					product = @event.products.find_by(id: params[:id])
					error!({ message: 'Product not found' }, 404) unless product
					result = product.change!(name: params[:name], price: params[:price], description: params[:description], quantity: params[:quantity], admin_id: @admin.id)
					if result[:success]
						present product: product, with: Api::Entities::Product
					else
						error!({ message: result[:message] }, 422)
					end
				end

				desc 'Delete a product' do
					summary 'Delete a product'
					detail 'Deletes a product from the event'
					tags ['Events']
					success Api::Entities::Product
					failure [[401, 'Unauthorized', Api::Entities::Error], [404, 'Product not found', Api::Entities::Error], [422, 'Unprocessable Entity', Api::Entities::Error]]
					headers AUTH_HEADER_DOC
				end
				params do
					requires :id, type: Integer
				end
				delete 'products/:id' do
					product = @event.products.find_by(id: params[:id])
					error!({ message: 'Product not found' }, 404) unless product
					result = product.delete!(admin_id: @admin.id)
					if result[:success]
						status :ok
						present product: product, with: Api::Entities::Product
					else
						error!({ message: result[:message] }, 422)
					end
				end

				desc 'Get event activity' do
					summary 'Get event activity'
					detail 'Returns a list of activities for the event'
					tags ['Events']
					success Api::Entities::Activity
					failure [[401, 'Unauthorized', Api::Entities::Error], [404, 'Event not found', Api::Entities::Error]]
					headers AUTH_HEADER_DOC
				end
				params do
				end
				get 'activity' do
					present @event.activities.order(created_at: :desc), with: Api::Entities::Activity
				end

				desc 'Get event transactions' do
					summary 'Get event transactions'
					detail 'Returns a list of transactions for the event'
					tags ['Events']
					success Api::Entities::Transaction
					failure [[401, 'Unauthorized', Api::Entities::Error], [404, 'Event not found', Api::Entities::Error]]
					headers AUTH_HEADER_DOC
				end
				params do
				end
				get 'transactions' do
					present @event.transactions.order(created_at: :desc), with: Api::Entities::Transaction
				end
			end

		
		end
	end
end
