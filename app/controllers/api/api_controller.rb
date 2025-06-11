
class Api::ApiController < ActionController::Base
    skip_before_action :verify_authenticity_token

    def docs
    end
end