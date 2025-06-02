class Api::BaseController < ApplicationController
    # before_action :authenticate_user!
    rescue_from StandardError, with: :handle_error
    private
    def authenticate_user!
        header = request.headers['Authorization']
        if header.present? && header.match(/^Bearer /)
        token = header.split(' ').last
        begin
            decoded = JWT.decode(token, Rails.application.secret_key_base)[0]
            @current_user = Admin.find(decoded['user_id'])
        rescue JWT::ExpiredSignature
            render json: { error: 'Token expired' }, status: :unauthorized
        rescue JWT::DecodeError
            render json: { error: 'Invalid token' }, status: :unauthorized
        end
        else
            render json: { error: 'Missing token' }, status: :unauthorized
        end
    end

    def handle_error(error)
        render json: { error: error.message }, status: :internal_server_error
    end
end
