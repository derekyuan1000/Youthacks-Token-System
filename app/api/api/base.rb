module Api
    class Base < Grape::API
        format :json

        get do
            status 200
            { message: 'Welcome to the API. Docs at /api/docs.' }
        end

        mount Api::Admins
        mount Api::Events
        mount Api::Managers

        add_swagger_documentation mount_path: '/docs'
    end
end