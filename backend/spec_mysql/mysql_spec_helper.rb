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
  module SourceDeletionCheckpoint
    def destroy!
      Thread.current[:before_regression_source_delete]&.call(self)
      super
    end
  end

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

  def competing_consumers(source, &operation)
    arrived = Queue.new
    connections = Queue.new
    outcomes = Queue.new
    releases = { first: Queue.new, second: Queue.new }
    workers = []
    start_worker = lambda do |role|
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do |connection|
          connections << [role, connection.select_value("SELECT CONNECTION_ID()").to_i]
          Thread.current[:before_regression_source_delete] = lambda do |record|
            next unless record.instance_of?(source.class) && record.id == source.id

            arrived << role
            releases.fetch(role).pop
          end
          begin
            outcomes << [:success, operation.call]
          rescue StandardError => e
            outcomes << [:error, e]
          ensure
            Thread.current[:before_regression_source_delete] = nil
          end
        end
      end
    end

    workers << start_worker.call(:first)
    first_connection = Timeout.timeout(10) { connections.pop }
    raise "first consumer did not reach source deletion" unless Timeout.timeout(10) { arrived.pop } == :first

    workers << start_worker.call(:second)
    second_connection = Timeout.timeout(10) { connections.pop }
    observation = Timeout.timeout(10) do
      loop do
        break :both_delete_ready unless arrived.empty?

        state = ActiveRecord::Base.uncached do
          ActiveRecord::Base.connection.select_value(
            "SELECT trx_state FROM information_schema.innodb_trx WHERE trx_mysql_thread_id = #{Integer(second_connection.last)}",
          )
        end
        break :lock_wait if state == "LOCK WAIT"

        # INNODB_TRX refresh needs >100ms idle since the last read; 20ms polling freezes its snapshot.
        # https://github.com/mysql/mysql-server/blob/mysql-8.0.46/storage/innobase/trx/trx0i_s.cc#L710-L726
        sleep 0.2
      end
    end

    releases[:first] << true
    raise "first consumer did not finish" unless workers.first.join(10)

    releases[:second] << true
    raise "second consumer did not finish" unless workers.last.join(10)

    { connection_ids: [first_connection.last, second_connection.last], observation: observation,
      outcomes: 2.times.map { outcomes.pop } }
  rescue Timeout::Error
    warn({ first_connection: first_connection, second_connection: second_connection }.inspect)
    warn workers.map { |worker| worker.backtrace&.first(8) }.inspect
    warn ActiveRecord::Base.connection.select_all("SELECT trx_mysql_thread_id, trx_state FROM information_schema.innodb_trx").to_a.inspect
    raise
  ensure
    releases&.each_value { |queue| queue << true }
    workers&.each do |worker|
      next if worker.join(2)

      worker.kill
      worker.join
    end
  end
end

IsolatedMysqlRegression.ensure_database!
require_relative "../spec/rails_helper"
Meal.prepend(IsolatedMysqlRegression::SourceDeletionCheckpoint)
PostponedMeal.prepend(IsolatedMysqlRegression::SourceDeletionCheckpoint)

RSpec.configure do |config|
  config.use_transactional_fixtures = false
  config.include IsolatedMysqlRegression
  config.before { IsolatedMysqlRegression.clean! }
  config.after { IsolatedMysqlRegression.clean! }
end
