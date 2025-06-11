module Api
    class Base < Grape::API
        format :json
        prefix 'api'

        get do
            status 200
            { message: 'Welcome to the API. Docs at /docs/api.' }
        end

        mount Api::Admins
        mount Api::Events
        mount Api::Managers

        add_swagger_documentation(
            info: {
                title: "Aha! API",
                description: "API documentation for Aha! event management system. Meant for internal use, but feel free to try it out!",
                contact_name: "Matthew",
                contact_email: "matthew@youthacks.org"
            
            },
            doc_version: 'v1',
            models: [
                Entities::Admin,
                Entities::Event,
                Entities::Participant,
                Entities::Product,
                Entities::Transaction,
                Entities::Activity
            ],
            mount_path: '/api/docs'
        )
    end
end