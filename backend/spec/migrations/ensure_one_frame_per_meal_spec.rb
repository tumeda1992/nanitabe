require "rails_helper"
require "tempfile"
require Rails.root.join("db/migrate/20261101000000_ensure_one_frame_per_meal")

class FrameCardinalityMigrationRecord < ActiveRecord::Base
  self.abstract_class = true
end

RSpec.describe EnsureOneFramePerMeal do
  let(:migration) { described_class.new }
  let(:connection) { FrameCardinalityMigrationRecord.connection }

  before do
    @database_file = Tempfile.new(["frame-cardinality", ".sqlite3"])
    FrameCardinalityMigrationRecord.establish_connection(adapter: "sqlite3", database: @database_file.path, pool: 3, timeout: 5000)
    connection.create_table(:meal_frame_entries) { |t| t.bigint :meal_id }
    connection.add_index(:meal_frame_entries, :meal_id, name: "index_meal_frame_entries_on_meal_id")
  end

  after do
    FrameCardinalityMigrationRecord.remove_connection
    @database_file.close!
  end

  it "stops without modifying existing duplicate assignments or their index" do
    connection.execute("INSERT INTO meal_frame_entries (meal_id) VALUES (7), (7), (NULL)")
    expect { migration.exec_migration(connection, :up) }.to raise_error(ActiveRecord::MigrationError, /複数枠/)
    expect(connection.select_values("SELECT meal_id FROM meal_frame_entries ORDER BY id")).to eq([7, 7, nil])
    expect(connection.indexes(:meal_frame_entries).first.unique).to eq(false)
  end

  it "preserves values, permits multiple NULLs, and restores the old index on down" do
    connection.execute("INSERT INTO meal_frame_entries (meal_id) VALUES (7), (NULL), (NULL)")
    migration.exec_migration(connection, :up)
    expect(connection.indexes(:meal_frame_entries).map { |index| [index.name, index.unique] }).to eq([["unique_meal_frame_entries_on_meal_id", true]])
    expect { connection.execute("INSERT INTO meal_frame_entries (meal_id) VALUES (7)") }.to raise_error(ActiveRecord::RecordNotUnique)
    migration.exec_migration(connection, :down)
    expect(connection.indexes(:meal_frame_entries).map { |index| [index.name, index.unique] }).to eq([["index_meal_frame_entries_on_meal_id", false]])
    expect(connection.select_values("SELECT meal_id FROM meal_frame_entries ORDER BY id")).to eq([7, nil, nil])
  end

  it "allows only one competing insert from independent SQLite connections" do
    migration.exec_migration(connection, :up)
    ready = Queue.new
    start = Queue.new
    threads = 2.times.map do
      Thread.new do
        FrameCardinalityMigrationRecord.connection_pool.with_connection do |writer|
          ready << true
          start.pop
          begin
            writer.execute("INSERT INTO meal_frame_entries (meal_id) VALUES (9)")
            :inserted
          rescue ActiveRecord::RecordNotUnique
            :rejected
          end
        end
      end
    end
    2.times { ready.pop }
    2.times { start << true }
    expect(threads.map(&:value).sort).to eq([:inserted, :rejected])
    expect(connection.select_value("SELECT COUNT(*) FROM meal_frame_entries WHERE meal_id = 9")).to eq(1)
  end
end
