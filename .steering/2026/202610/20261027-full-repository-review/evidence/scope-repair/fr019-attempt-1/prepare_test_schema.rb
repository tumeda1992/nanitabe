require "pathname"
expected = Rails.root.join("db/test.sqlite3").cleanpath
verify = lambda do
  config = ActiveRecord::Base.connection_db_config.configuration_hash
  configured = Pathname.new(config.fetch(:database).to_s)
  configured = Rails.root.join(configured) if configured.relative?
  abort "Refusing schema preparation outside the standard SQLite test DB" unless Rails.env.test? && config[:adapter] == "sqlite3" && configured.cleanpath == expected
  connection = ActiveRecord::Base.connection
  actual = connection.select_all("PRAGMA database_list").to_a.find { |row| row["name"] == "main" }.fetch("file")
  abort "SQLite connection does not match the guarded test DB" unless Pathname.new(actual).realpath == expected.realpath
  connection
end
unique_index = ->(connection) { connection.indexes(:meal_frame_entries).any? { |index| index.unique && index.columns == ["meal_id"] } }
connection = verify.call
if unique_index.call(connection)
  puts "guard_passed: reloading standard test schema to remove the remaining unique index"
  connection.disconnect!
  abort "Test schema load failed" unless system({ "RAILS_ENV" => "test" }, "bundle", "exec", "rails", "db:schema:load", "RAILS_ENV=test")
  ActiveRecord::Base.establish_connection(:test)
  connection = verify.call
else
  puts "guard_passed: schema reload unnecessary"
end
abort "Unique meal assignment index remains" if unique_index.call(connection)
puts "standard_test_db_ready: unique meal assignment index absent"
