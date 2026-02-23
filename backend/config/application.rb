require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Backend
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
    config.time_zone = "Asia/Tokyo"
    # config.active_record.default_timezone = 'Tokyo'
    config.active_record.default_timezone = :local

    config.encoding = "utf-8"

    config.autoload_paths += ["#{config.root}/app/domain"]
    config.autoload_paths += ["#{config.root}/lib"]

    config.generators do |g|
      g.stylesheets false
      g.javascripts false
      g.helper false
      g.template_engine false
      g.test_framework :rspec, fixtures: true, model_specs: false
      g.factory_bot dir: "spec/support/factories"
    end

    # https://qiita.com/guri3/items/268dc4f8be4bafe5029f
    config.middleware.insert_before 0, Rack::Cors do
      allow do
        origins "*"

        resource "*",
                 headers: :any,
                 methods: [:get, :post, :put, :patch, :delete, :options, :head],
                 expose: ["Per-Page", "Total", "Link", "Authorization"]
      end
    end

    config.hosts << ENV.fetch("FRONTEND_PROD_HOST", "")

    config.hosts << "nanitabe_back"
    config.hosts << ENV.fetch("BACKEND_PROD_HOST", "")
  end
end
