require_relative "mysql_spec_helper"
require_relative "../db/migrate/20261101000000_ensure_one_frame_per_meal"

RSpec.describe "MySQL one frame per meal" do
  let(:owner) { FactoryBot.create(:user, id_param: "mysql-frame-owner") }
  let(:meal) { FactoryBot.create(:meal, user: owner, dish: FactoryBot.create(:dish, user: owner)) }
  let(:entries) do
    2.times.map do |index|
      frame = MealFrame.create!(user: owner, name: "枠#{index}")
      MealFrameEntry.create!(user: owner, meal_frame: frame, date: meal.date, meal_type: meal.meal_type)
    end
  end

  def unique_meal_index?
    ActiveRecord::Base.connection.index_exists?(:meal_frame_entries, :meal_id, unique: true, name: "unique_meal_frame_entries_on_meal_id")
  end

  def race(entries)
    ready = Queue.new
    release = Queue.new
    outcomes = Queue.new
    workers = entries.map do |entry|
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do |connection|
          ready << connection.select_value("SELECT CONNECTION_ID()").to_i
          release.pop
          begin
            outcomes << [:success, yield(entry)]
          rescue StandardError => e
            outcomes << [:error, e]
          end
        end
      end
    end
    ids = Timeout.timeout(10) { 2.times.map { ready.pop } }
    2.times { release << true }
    workers.each { |worker| raise "frame race did not finish" unless worker.join(10) }
    expect(ids.uniq.size).to eq(2)
    2.times.map { outcomes.pop }
  ensure
    2.times { release << true } if release
    workers&.each { |worker| worker.kill.join unless worker.join(2) }
  end

  it "migrates down and up with MySQL foreign keys and multiple NULL assignments intact" do
    entries
    migration = EnsureOneFramePerMeal.new
    migration.down
    expect(unique_meal_index?).to be(false)
    migration.up
    expect(unique_meal_index?).to be(true)
    expect(MealFrameEntry.where(meal_id: nil).count).to eq(2)
    expect(ActiveRecord::Base.connection.foreign_keys(:meal_frame_entries).map(&:to_table)).to include("meals")
  ensure
    migration&.up unless unique_meal_index?
  end

  it "refuses duplicate legacy assignments without changing or silently deleting them" do
    targets = entries
    migration = EnsureOneFramePerMeal.new
    migration.down
    MealFrameEntry.where(id: targets.map(&:id)).update_all(meal_id: meal.id)
    before = MealFrameEntry.order(:id).map(&:attributes)
    expect { migration.up }.to raise_error(ActiveRecord::MigrationError, /複数枠/)
    expect(unique_meal_index?).to be(false)
    expect(MealFrameEntry.order(:id).map(&:attributes)).to eq(before)
  ensure
    MealFrameEntry.update_all(meal_id: nil)
    migration&.up unless unique_meal_index?
  end

  it "allows only one Command to assign the same meal from two independent connections" do
    meal_id = meal.id
    user_id = owner.id
    outcomes = race(entries) do |entry|
      Business::Food::Meal::Frame::Entry::Usecase::FillWithMealCommand.call(
        user_id: user_id, meal_frame_entry_id: entry.id, meal_id: meal_id,
      )
    end
    expect(outcomes.count { |kind, _| kind == :success }).to eq(1)
    errors = outcomes.select { |kind, _| kind == :error }.map(&:last)
    expect(errors.map(&:message)).to eq(["この食事は既に別の枠に割り当てられています。"])
    expect(MealFrameEntry.where(meal_id: meal_id).count).to eq(1)
  end

  it "rejects a concurrent duplicate write at the database even when Commands are bypassed" do
    meal_id = meal.id
    outcomes = race(entries) { |entry| entry.update!(meal_id: meal_id) }
    expect(outcomes.count { |kind, _| kind == :success }).to eq(1)
    expect(outcomes.select { |kind, _| kind == :error }.map { |_, error| error.class }).to eq([ActiveRecord::RecordNotUnique])
    expect(MealFrameEntry.where(meal_id: meal_id).count).to eq(1)
  end
end
