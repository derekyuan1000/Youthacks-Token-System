module Api
	class Events < Admins

		helpers do
			params :auth_header do
				requires :Authorization, type: String, desc: 'Admin authorization token', documentation: { param_type: 'header' }
			end

			def require_event!(event_slug:)
				error!({ error: 'Event ID is required' }, 400) if event_slug.blank?

				@event = Event.find_by(slug: event_slug)
				error!({ error: 'Event not found' }, 404) if @event.nil?

				unless @event.admins.include?(@admin) || @event.manager.id == @admin.id
					error!({ error: 'Unauthorized access to event' }, 403)
				end
			end
		end

		before do
			helpers.require_admin!
		end
		
		resource :events do
			route_param :event_slug, type: String do
		
				before do
					require_event!(event_slug: params[:event_slug])
				end

				desc 'Get participants for an event', {
					tags: ['Events'],
					detail: 'Returns a list of active participants for the specified event',
					documentation: { operationId: 'getParticipants' }
				}
				params do
					use :auth_header
				end
				get 'participants' do
					present participants: @event.participants.active, with: Api::Entities::Participant
				end

				desc 'Add a participant to an event', {
					tags: ['Events'],
					detail: 'Creates a new participant in the event',
					documentation: { operationId: 'postParticipants' }
				}
				params do
					use :auth_header
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
						present participant: result[:participant], with: Api::Entities::Participant::Public
					else
						error!({ message: result[:message] }, 422)
					end
				end

				desc 'Sync participants for an event', {
					tags: ['Events'],
					detail: 'Synchronizes participants data for the event',
					documentation: { operationId: 'postSyncParticipants' }
				}
				params do
					use :auth_header
				end
				post 'sync_participants' do
					result = @event.sync
					if result[:success]
						status :ok
						present participants: @event.participants.active, with: Api::Entities::Participant::Public
					else
						error!({ message: result[:message] || "Failed to sync participants" }, 422)
					end
				end

				desc 'Set participant balance', {
					tags: ['Events'],
					detail: 'Sets the balance for a participant in the event',
					documentation: { operationId: 'postParticipantSetBalance' }
				}
				params do
					use :auth_header
					requires :participant_id, type: Integer
					requires :balance, type: Integer
				end
				post 'participants/:participant_id/set_balance' do
					participant = @event.participants.find_by(id: params[:participant_id])
					error!({ error: 'Participant not found' }, 404) unless participant
					participant.set_balance!(params[:balance], @admin.id)
					present participant: participant, with: Api::Entities::Participant::Public
				end

				desc 'Earn points for participant', {
					tags: ['Events'],
					detail: 'Adds points to a participant\'s balance',
					documentation: { operationId: 'postParticipantEarn' }
				}
				params do
					use :auth_header
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
						present participant: participant, with: Api::Entities::Participant::Public
					else
						error!({ message: result[:message] }, 422)
					end
				end

				desc 'Participant buys a product', {
					tags: ['Events'],
					detail: 'Processes a purchase transaction for a participant',
					documentation: { operationId: 'postParticipantBuy' }
				}
				params do
					use :auth_header
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
						present transaction: result[:transaction], with: Api::Entities::Transaction
					else
						error!({ message: result[:message] }, 422)
					end
				end

				desc 'Check in a participant', {
					tags: ['Events'],
					detail: 'Checks in a participant to the event',
					documentation: { operationId: 'postParticipantCheckIn' }
				}
				params do
					use :auth_header
					requires :participant_id, type: Integer
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

				desc 'Delete a participant', {
					tags: ['Events'],
					detail: 'Deletes a participant from the event',
					documentation: { operationId: 'deleteParticipant' }
				}
				params do
					use :auth_header
					requires :participant_id, type: Integer
				end
				delete 'participants/:participant_id' do
					participant = @event.participants.find_by(id: params[:participant_id])
					error!({ error: 'Participant not found' }, 404) unless participant
					result = participant.delete!(@admin.id)
					if result[:success]
						status :ok
						present participant: participant, with: Api::Entities::Participant::Public
					else
						error!({ message: result[:message] }, 422)
					end
				end

				desc 'Get products for an event', {
					tags: ['Events'],
					detail: 'Returns a list of active products for the event',
					documentation: { operationId: 'getProducts' }
				}
				params do
					use :auth_header
				end
				get 'products' do
					present @event.products.active, with: Api::Entities::Product
				end

				desc 'Create a product for an event', {
					tags: ['Events'],
					detail: 'Creates a new product for the event',
					documentation: { operationId: 'postProducts' }
				}
				params do
					use :auth_header
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

				desc 'Update a product', {
					tags: ['Events'],
					detail: 'Updates details of a product',
					documentation: { operationId: 'putProduct' }
				}
				params do
					use :auth_header
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
						present product: product, with: Api::Entities::Product
					else
						error!({ message: result[:message] }, 422)
					end
				end

				desc 'Delete a product', {
					tags: ['Events'],
					detail: 'Deletes a product from the event',
					documentation: { operationId: 'deleteProduct' }
				}
				params do
					use :auth_header
					requires :id, type: Integer
				end
				delete 'products/:id' do
					product = @event.products.find_by(id: params[:id])
					error!({ error: 'Product not found' }, 404) unless product
					result = product.delete!(admin_id: @admin.id)
					if result[:success]
						status :ok
						present product: product, with: Api::Entities::Product
					else
						error!({ message: result[:message] }, 422)
					end
				end

				desc 'Get event activity', {
					tags: ['Events'],
					detail: 'Returns a list of activities for the event',
					documentation: { operationId: 'getActivity' }
				}
				params do
					use :auth_header
				end
				get 'activity' do
					present @event.activities.order(created_at: :desc), with: Api::Entities::Activity
				end

				desc 'Get event transactions', {
					tags: ['Events'],
					detail: 'Returns a list of transactions for the event',
					documentation: { operationId: 'getTransactions' }
				}
				params do
					use :auth_header
				end
				get 'transactions' do
					present @event.transactions.order(created_at: :desc), with: Api::Entities::Transaction
				end
			end

		
		end
	end
end
