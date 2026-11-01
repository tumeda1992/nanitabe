require_relative "mysql_spec_helper"

RSpec.describe "MySQL single consumption of meal conversions" do
  %i[schedule postpone].each do |direction|
    it "consumes the source once for two competing #{direction} requests" do
      owner = FactoryBot.create(:user, id_param: "mysql-conversion-owner")
      dish = FactoryBot.create(:dish, user: owner)
      if direction == :schedule
        source = PostponedMeal.create!(user: owner, dish: dish, meal_type: 3, comment: "保持するコメント")
        destination = Meal
        resolver = Mutations::Meal::Postponed::SchedulePostponedMeal
        arguments = { postponed_meal_id: source.id, date: Date.new(2026, 11, 2) }
        missing = "指定した延期された食事は存在しません。"
      else
        source = Meal.create!(user: owner, dish: dish, meal_type: 3, date: Date.new(2026, 11, 2), comment: "保持するコメント")
        frame = MealFrame.create!(user: owner, name: "残す枠")
        entry = MealFrameEntry.create!(user: owner, meal_frame: frame, meal: source, date: source.date, meal_type: 3)
        destination = PostponedMeal
        resolver = Mutations::Meal::Postponed::PostponeMeal
        arguments = { meal_id: source.id }
        missing = "指定した食事は存在しません。"
      end

      result = competing_consumers(source) do
        context = GraphQL::Query.new(BackendSchema, "{ __typename }", context: { current_user_id: owner.id }).context
        resolver.new(object: nil, context: context, field: nil).resolve(**arguments)
      end
      successes = result[:outcomes].select { |kind, _| kind == :success }
      errors = result[:outcomes].select { |kind, _| kind == :error }.map(&:last)
      RSpec.configuration.reporter.message("#{direction}: sessions=#{result[:connection_ids].uniq.size}, observation=#{result[:observation]}, successes=#{successes.size}, errors=#{errors.map(&:class)}")

      expect(result[:connection_ids].uniq.size).to eq(2)
      expect(destination.count).to eq(1)
      expect(successes.size).to eq(1)
      expect(errors.size).to eq(1)
      expect(errors.first).to be_a(RuntimeError)
      expect(errors.first.message).to eq(missing)
      expect(result[:observation]).to eq(:lock_wait)
      expect(source.class.exists?(source.id)).to be(false)
      expect(destination.last.attributes.slice("dish_id", "meal_type", "comment")).to eq(
        "dish_id" => dish.id, "meal_type" => 3, "comment" => "保持するコメント",
      )
      expect(entry.reload.meal_id).to be_nil if entry
    end
  end
end
