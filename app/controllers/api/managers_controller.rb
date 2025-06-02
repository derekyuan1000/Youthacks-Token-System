class Api::ManagersController < Api::EventsController
    before_action :require_manager

    def settings
        render json: {
          event: @event.as_json(only: [:name, :description, :slug, :date, :sync_with_airtable]).merge(
            airtable_config: {
              api_key: @event.airtable_api_key,
              base_id: @event.airtable_base_id,
              table_name: @event.airtable_table_name,
              name_column: @event.name_column
            }
          )
        }, status: :ok
    end
    def update_settings
        @event.update(params.permit(:name, :description, :date))
        settings
    end

    def update_airtable
        if @event.sync_with_airtable
            @event.update(
                params.permit(:airtable_api_key, :airtable_base_id, :airtable_table_name, :name_column)
            )
            settings
        else
            render json: { message: 'Event is not set to sync with Airtable' }, status: :forbidden
        end
    end

    def admins
        render json: {
            admins: @event.admins.as_json(only: [:id, :name, :email])
        }, status: :ok
    end

    def invite_admin
        admin = Admin.find_by(name: params[:name])
        unless admin.present? and admin.id != @event.manager_id && !@event.admins.exists?(admin.id)
            raise "Invalid admin ID or admin already exists for this event."
        end
        result = AdminInvitation.create!(event_id: @event.id, admin_id: admin.id)
        if result[:success]
            render json: {}, status: :created
        else
            raise result[:message]
        end
    rescue => e
        render json: {message: "Failed to invite admin: #{e.message}"}. status: :unprocessable_entity
    end

    private
    def require_manager
        unless @event.manager_id == @admin.id
            render json: { error: 'Unauthorized access' }, status: :forbidden
        end
    end 
end
