class EventManagersController < EventController
    before_action :require_manager

    

    private
    def require_manager
        unless @event.manager_id == @admin.id
            redirect_to dashboard_path, alert: "Manager access required."
        end
end
