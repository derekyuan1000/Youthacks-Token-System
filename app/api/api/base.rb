module Api
    class Base < Grape::API
        format :json
        default_format :json
        prefix :api

        get do
            status 200
            { message: 'Welcome to the API. Docs at aha.youthacks.org/docs/api.' }
        end
       

        mount Api::Admins
        mount Api::Events
        mount Api::Managers

        add_swagger_documentation(
            info: {
                title: "Aha! API",
                description: "API documentation for Aha! event management system. Meant for internal use, but feel free to try it out!",
                contact_name: "Youthacks",
                contact_email: "aha@youthacks.org"
            
            },
            doc_version: 'v1',
            models: [
                Api::Entities::Admin::Public,
                Api::Entities::Admin::Full,
                Api::Entities::Event::Public,
                Api::Entities::Event::Member,
                Api::Entities::Event::Full,
                Api::Entities::Participant::Public,
                Api::Entities::Participant::Full,
                Api::Entities::Product,
                Api::Entities::Transaction,
                Api::Entities::Activity,
                Api::Entities::Error
            ],
            array_use_braces: true,

            mount_path: '/docs'
        )
        route :any, '*path' do
            error!({ error: 'Not Found. Check aha.youthacks.org/docs/api for documentation.' }, 404)
        end
    end
end