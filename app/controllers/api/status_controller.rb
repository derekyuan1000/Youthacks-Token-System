module Api
    class StatusController < ApplicationController
        def index
        render json: { status: 'ok' }, status: :ok
        end
    
        def health_check
        render json: { status: 'healthy' }, status: :ok
        end
    
        def ping
        render json: { message: 'pong' }, status: :ok
        end
    end
end