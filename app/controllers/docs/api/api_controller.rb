
class Docs::Api::ApiController < ActionController::Base
    skip_before_action :verify_authenticity_token

    def docs
        Rails.logger.info "Rendering docs page"
  # raise "In docs action"  # uncomment to force stop and see if called
         render template: 'docs/api/api/docs', layout: false
    end
end