module Api
  class SessionsController < ApplicationController
    def create
      user = Admin.find_by(name: params[:name])
      if user&.authenticate(params[:password])
        token = generate_token(user)  # implement token generation (e.g., JWT)
        render json: { token: token, user: user }
      else
        render json: { error: "Invalid email or password" }, status: :unauthorized
      end
    end

    private

    def generate_token(user)
    end
  end
end