module Api
    module Helpers
        def require_admin!
            header = headers['Authorization']
            token = header&.split(' ')&.last

            error!({ message: 'Missing token' }, 401) if token.blank?

            begin
                decoded = JWT.decode(token, Rails.application.secret_key_base)[0]
                @admin = Admin.find(decoded['user_id'])
                rescue JWT::ExpiredSignature
                    error!({ message: 'Token expired' }, 401)
                rescue JWT::DecodeError
                    error!({ message: 'Invalid token' }, 401)
                rescue ActiveRecord::RecordNotFound
                    error!({ message: 'Admin not found' }, 401)
            end
        end
        def require_event!
            event_id = params[:event_id]
            error!({ message: 'Event ID is required' }, 400) if event_id.blank?

            @event = Event.find_by(id: event_id)
            error!({ message: 'Event not found' }, 404) if @event.nil?

            unless @event.admins.include?(@admin) || @event.manager.id == @admin.id
                error!({ message: 'Unauthorized access to event' }, 403)
            end
        end
        def require_manager!
            error!({ message: 'Unauthorized access to manage' }, 403) unless @event.manager_id == @admin.id
        end
    end
end