module Api
  class Status < Grape::API
    format :json
    prefix :api

    resource :status do
      get do
        present status: 'ok'
      end

      get :health_check do
        present status: 'healthy'
      end

      get :ping do
        present message: 'pong'
      end
    end
  end
end