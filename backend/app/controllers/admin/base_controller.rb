module Admin
  class BaseController < ApplicationController
    before_action :authenticate_admin!

    private

    def authenticate_admin!
      authenticate_or_request_with_http_basic("Administration") do |username, password|
        configured_username = ENV.fetch("ADMIN_USERNAME", nil)
        configured_password = ENV.fetch("ADMIN_PASSWORD", nil)
        configured_username.present? && configured_password.present? &&
          ActiveSupport::SecurityUtils.secure_compare(username.to_s, configured_username) &&
          ActiveSupport::SecurityUtils.secure_compare(password.to_s, configured_password)
      end
    end
  end
end
