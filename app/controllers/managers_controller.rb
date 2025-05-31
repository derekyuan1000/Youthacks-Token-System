class ManagersController < EventsController
    before_action :require_manager

    def settings
    end

    def update_settings
        @event.update!(name: params[:name], description: params[:description], date: params[:date])
        redirect_to event_dashboard_path(@event.slug), notice: "Event settings updated successfully."
    rescue => e
        redirect_to event_settings_path(@event.slug), alert: "Failed to update event settings: #{e.message}"
    end

    def update_airtable
        @event.update(airtable_api_key: params[:airtable_api_key], airtable_base_id: params[:airtable_base_id])
        redirect_to event_settings_path(@event.slug), notice: "Airtable settings updated successfully."
    rescue => e
        redirect_to event_settings_path(@event.slug), alert: "Failed to update Airtable settings: #{e.message}"
    end

    def update_airtable_table
        @event.update(airtable_table_name: params[:airtable_table_name], name_column: params[:name_column])
        redirect_to event_settings_path(@event.slug), notice: "Airtable table settings updated successfully."
    rescue => e
        redirect_to event_settings_path(@event.slug), alert: "Failed to update Airtable table settings: #{e.message}"
    end

    private
    def require_manager
        unless @event.manager_id == @admin.id
            redirect_to event_dashboard_path, alert: "Manager access required."
        end
    end 
end
