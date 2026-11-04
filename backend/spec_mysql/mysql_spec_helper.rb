require "uri"
require "timeout"

begin
  url = URI.parse(ENV.fetch("DATABASE_URL", ""))
rescue URI::InvalidURIError
  abort "MySQL regression requires a valid isolated fixture URL"
end
unless ENV["RAILS_ENV"] == "test" && url.scheme == "mysql2" && url.host == "mysql-regression" &&
       url.path == "/nanitabe_concurrency_test" && url.user == "regression"
  abort "MySQL regression requires the isolated mysql-regression fixture URL and RAILS_ENV=test"
end

require_relative "../config/environment"

module IsolatedMysqlRegression
  def self.ensure_database!
    config = ActiveRecord::Base.connection_db_config.configuration_hash
    unless Rails.env.test? && config.values_at(:adapter, :host, :database) == ["mysql2", "mysql-regression", "nanitabe_concurrency_test"] &&
           ActiveRecord::Base.connection.select_value("SELECT DATABASE()") == "nanitabe_concurrency_test"
      abort "Refusing to modify a database outside the isolated MySQL fixture"
    end
  end

  def self.clean!
    ensure_database!
    [MealFrameEntry, MealFramePatternEntry, MealFramePattern, MealFrame, Meal, PostponedMeal,
     DishTag, DishSourceRelation, DishEvaluation, Dish, DishSource, DishEffortLevel, LoginUser, User, NormalizeWord].each(&:delete_all)
  end
end

IsolatedMysqlRegression.ensure_database!
require_relative "../spec/rails_helper"

RSpec.configure do |config|
  config.use_transactional_fixtures = false
  config.include IsolatedMysqlRegression
  config.before { IsolatedMysqlRegression.clean! }
  config.after { IsolatedMysqlRegression.clean! }
end
