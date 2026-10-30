module Admin
  class BaseController < ApplicationController
    before_action :authenticate_admin!

    private

    def authenticate_admin!
      authenticate_or_request_with_http_basic("Administration") do |username, password|
        configured_username = ENV["ADMIN_USERNAME"]
        configured_password = ENV["ADMIN_PASSWORD"]
        configured_username.present? && configured_password.present? &&
          ActiveSupport::SecurityUtils.secure_compare(username.to_s, configured_username) &&
          ActiveSupport::SecurityUtils.secure_compare(password.to_s, configured_password)
      end
    end
  end
end
