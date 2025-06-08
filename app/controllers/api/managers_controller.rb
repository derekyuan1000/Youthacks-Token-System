module API
  class Managers < Events
    route_param :event_slug do
    before {require_manager!}

        get :settings do
            present event: @event, with: API::Entities::Event::Full
        end

        params do
            requires :name, type: String
            optional :description, type: String
            optional :date, type: Date
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
        post :update_airtable do
            if @event.sync_with_airtable
                @event.update!(declared(params, include_missing: false))
                present @event, with: API::Entities::Event::Full
            else
            error!({ message: 'Event is not set to sync with Airtable' }, 403)
            end
        end

        get :admins do
            present @event.admins, with: API::Entities::Admin::Public
        end

        params do
            requires :name, type: String
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
