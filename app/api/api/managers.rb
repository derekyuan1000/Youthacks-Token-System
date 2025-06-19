module Api
  class Managers < Admins
    helpers do
        def require_event!(event_slug:)
            error!({ error: 'Event ID is required' }, 400) if event_slug.blank?

            @event = Event.find_by(slug: event_slug)
            error!({ error: 'Event not found' }, 404) if @event.nil?

            unless @event.admins.include?(@admin) || @event.manager.id == @admin.id
                error!({ error: 'Unauthorized access to event' }, 403)
            end
        end
        def require_manager!
            error!({ error: 'Unauthorized access to manage' }, 403) unless @event.manager_id == @admin.id
        end
    end
    
    route_param :event_slug, type: String do
        before do
            require_event!(event_slug: :event_slug)
            require_manager!
        end
        desc 'Get event settings' do
          summary 'Get event settings'
          detail 'Returns full configuration details of the event the manager is responsible for'
          tags ['Event Managers']
          success Api::Entities::Event::Full
          failure [[400, 'Missing or invalid event', Api::Entities::Error], [403, 'Unauthorized access', Api::Entities::Error]]
        end
        get :settings do
            present event: @event, with: Api::Entities::Event::Full
        end

        params do
            requires :name, type: String
            optional :description, type: String
            optional :date, type: Date
        end
        desc 'Update event settings' do
          summary 'Update event settings'
          detail 'Updates the event settings like name, description, and date for the managed event'
          tags ['Event Managers']
          success Api::Entities::Event::Full
          failure [[400, 'Invalid parameters', Api::Entities::Error], [403, 'Unauthorized access', Api::Entities::Error]]
        end
        post :update_settings do
            @event.update!(declared(params, include_missing: false))
        end

        params do
            optional :airtable_api_key, type: String
            optional :airtable_base_id, type: String
            optional :airtable_table_name, type: String
            optional :name_column, type: String
        end
        desc 'Update Airtable settings' do
          summary 'Update Airtable settings'
          detail 'Updates Airtable integration settings for the event if syncing is enabled'
          tags ['Event Managers']
          success Api::Entities::Event::Full
          failure [[403, 'Event is not set to sync with Airtable', Api::Entities::Error], [400, 'Invalid parameters', Api::Entities::Error]]
        end
        post :update_airtable do
            if @event.sync_with_airtable
                @event.update!(declared(params, include_missing: false))
                present @event, with: Api::Entities::Event::Full
            else
            error!({ message: 'Event is not set to sync with Airtable' }, 403)
            end
        end

        desc 'List event admins' do
          summary 'List event admins'
          detail 'Returns a list of admins associated with the managed event'
          tags ['Event Managers']
          success Api::Entities::Admin::Public
          failure [[403, 'Unauthorized access', Api::Entities::Error]]
        end
        get :admins do
            present @event.admins, with: Api::Entities::Admin::Public
        end

        params do
            requires :name, type: String
        end
        desc 'Invite event admin' do
          summary 'Invite event admin'
          detail 'Invites a new admin to the event by name if they are not already associated'
          tags ['Event Managers']
          success nil
          failure [[422, 'Invalid admin ID or admin already exists', Api::Entities::Error], [403, 'Unauthorized access', Api::Entities::Error]]
        end
        post :invite_admin do
            admin = Admin.find_by(name: params[:name])
            unless admin.present? && admin.id != @event.manager_id && !@event.admins.exists?(admin.id)
                error!({ message: 'Invalid admin ID or admin already exists for this event.' }, 422)
            end
            result = AdminInvitation.create!(event_id: @event.id, admin_id: admin.id)
            if result[:success]
                status 201
                body false
            else
            error!({ message: result[:message] }, 422)
            end
        end
        end
  end
end
