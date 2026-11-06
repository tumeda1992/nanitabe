require "rails_helper"
require_relative "../../../../../support/factories/user_repository"
require_relative "../../../../../support/factories/dish_repository"

RSpec.describe Business::Food::Meal::Usecase::SwapMealsBetweenDaysCommand do
  let(:user_record) { find_or_create_user }
  let(:dish1_record) { find_or_create_dish }
  let(:dish2_record) { FactoryBot.create(:dish, user: user_record) }
  let(:dish3_record) { FactoryBot.create(:dish, user: user_record) }

  let(:date1) { Date.parse("2023-01-01") }
  let(:date2) { Date.parse("2023-01-02") }

  describe "validations" do
    context "when user_id is missing" do
      it "raises validation error" do
        expect {
          described_class.call(
            date1: date1,
            date2: date2,
          )
        }.to raise_error(/User can't be blank/)
      end
    end

    context "when date1 is missing" do
      it "raises validation error" do
        expect {
          described_class.call(
            user_id: user_record.id,
            date2: date2,
          )
        }.to raise_error(/Date1 can't be blank/)
      end
    end

    context "when date2 is missing" do
      it "raises validation error" do
        expect {
          described_class.call(
            user_id: user_record.id,
            date1: date1,
          )
        }.to raise_error(/Date2 can't be blank/)
      end
    end

    context "when user_id is nil" do
      it "raises validation error" do
        expect {
          described_class.call(
            user_id: nil,
            date1: date1,
            date2: date2,
          )
        }.to raise_error(/User can't be blank/)
      end
    end

    context "when date1 is nil" do
      it "raises validation error" do
        expect {
          described_class.call(
            user_id: user_record.id,
            date1: nil,
            date2: date2,
          )
        }.to raise_error(/Date1 can't be blank/)
      end
    end

    context "when date2 is nil" do
      it "raises validation error" do
        expect {
          described_class.call(
            user_id: user_record.id,
            date1: date1,
            date2: nil,
          )
        }.to raise_error(/Date2 can't be blank/)
      end
    end
  end

  describe "#call" do
    it "does not move another user's meals on either date" do
      other = FactoryBot.create(:user, id_param: "fr002-other-user")
      own_meal = FactoryBot.create(:meal, user: user_record, dish: dish1_record, date: date1)
      foreign = [date1, date2].map { |date| FactoryBot.create(:meal, user: other, dish: FactoryBot.create(:dish, user: other), date: date) }
      snapshots = foreign.map(&:attributes)
      result = described_class.call(user_id: user_record.id, date1: date1, date2: date2)
      expect(result.map(&:id)).to eq([own_meal.id])
      expect(own_meal.reload.date).to eq(date2)
      expect(foreign.map { |meal| meal.reload.attributes }).to eq(snapshots)
    end

    context "with meals on both dates" do
      let!(:date1_meal1) do
        FactoryBot.create(
          :meal,
          user: user_record,
          dish: dish1_record,
          date: date1,
          meal_type: 1,
          comment: "date1 meal1",
        )
      end
      let!(:date1_meal2) do
        FactoryBot.create(
          :meal,
          user: user_record,
          dish: dish2_record,
          date: date1,
          meal_type: 2,
          comment: "date1 meal2",
        )
      end
      let!(:date2_meal1) do
        FactoryBot.create(
          :meal,
          user: user_record,
          dish: dish3_record,
          date: date2,
          meal_type: 1,
          comment: "date2 meal1",
        )
      end

      it "swaps meals between the two dates" do
        result = described_class.call(
          user_id: user_record.id,
          date1: date1,
          date2: date2,
        )

        expect(result).to be_an(Array)
        expect(result.length).to eq(3)

        # Check that all meals have been moved to the opposite dates
        expect(Meal.where(date: date1).count).to eq(1)
        expect(Meal.where(date: date2).count).to eq(2)

        # Verify specific meal movements
        moved_date2_meal = Meal.find(date2_meal1.id)
        expect(moved_date2_meal.date).to eq(date1)

        moved_date1_meals = Meal.where(id: [date1_meal1.id, date1_meal2.id])
        moved_date1_meals.each do |meal|
          expect(meal.date).to eq(date2)
        end
      end

      it "preserves all meal attributes except date" do
        described_class.call(
          user_id: user_record.id,
          date1: date1,
          date2: date2,
        )

        all_meals = Meal.where(id: [date1_meal1.id, date1_meal2.id, date2_meal1.id])

        moved_meal1 = all_meals.find(date1_meal1.id)
        expect(moved_meal1.meal_type).to eq(1)
        expect(moved_meal1.comment).to eq("date1 meal1")
        expect(moved_meal1.dish_id).to eq(dish1_record.id)
        expect(moved_meal1.user_id).to eq(user_record.id)
        expect(moved_meal1.date).to eq(date2)

        moved_meal2 = all_meals.find(date1_meal2.id)
        expect(moved_meal2.meal_type).to eq(2)
        expect(moved_meal2.comment).to eq("date1 meal2")
        expect(moved_meal2.dish_id).to eq(dish2_record.id)
        expect(moved_meal2.user_id).to eq(user_record.id)
        expect(moved_meal2.date).to eq(date2)

        moved_meal3 = all_meals.find(date2_meal1.id)
        expect(moved_meal3.meal_type).to eq(1)
        expect(moved_meal3.comment).to eq("date2 meal1")
        expect(moved_meal3.dish_id).to eq(dish3_record.id)
        expect(moved_meal3.user_id).to eq(user_record.id)
        expect(moved_meal3.date).to eq(date1)
      end
    end

    context "with meals only on date1" do
      let!(:date1_meal) do
        FactoryBot.create(
          :meal,
          user: user_record,
          dish: dish1_record,
          date: date1,
          meal_type: 1,
          comment: "only date1 meal",
        )
      end

      it "moves date1 meals to date2" do
        result = described_class.call(
          user_id: user_record.id,
          date1: date1,
          date2: date2,
        )

        expect(result.length).to eq(1)

        expect(Meal.where(date: date1).count).to eq(0)
        expect(Meal.where(date: date2).count).to eq(1)

        moved_meal = Meal.where(date: date2).first
        expect(moved_meal.dish_id).to eq(dish1_record.id)
        expect(moved_meal.comment).to eq("only date1 meal")
        expect(moved_meal.meal_type).to eq(1)
        expect(moved_meal.user_id).to eq(user_record.id)
      end
    end

    context "with meals only on date2" do
      let!(:date2_meal) do
        FactoryBot.create(
          :meal,
          user: user_record,
          dish: dish1_record,
          date: date2,
          meal_type: 1,
          comment: "only date2 meal",
        )
      end

      it "moves date2 meals to date1" do
        result = described_class.call(
          user_id: user_record.id,
          date1: date1,
          date2: date2,
        )

        expect(result.length).to eq(1)

        expect(Meal.where(date: date1).count).to eq(1)
        expect(Meal.where(date: date2).count).to eq(0)

        moved_meal = Meal.where(date: date1).first
        expect(moved_meal.dish_id).to eq(dish1_record.id)
        expect(moved_meal.comment).to eq("only date2 meal")
        expect(moved_meal.meal_type).to eq(1)
        expect(moved_meal.user_id).to eq(user_record.id)
      end
    end

    context "with no meals on either date" do
      it "returns empty array" do
        result = described_class.call(
          user_id: user_record.id,
          date1: date1,
          date2: date2,
        )

        expect(result).to eq([])
        expect(Meal.where(date: date1).count).to eq(0)
        expect(Meal.where(date: date2).count).to eq(0)
      end
    end

    context "with same date for both parameters" do
      let!(:same_date_meal) do
        FactoryBot.create(
          :meal,
          user: user_record,
          dish: dish1_record,
          date: date1,
          meal_type: 1,
          comment: "same date meal",
        )
      end

      it "does not change anything when swapping same date" do
        original_count = Meal.where(date: date1).count

        result = described_class.call(
          user_id: user_record.id,
          date1: date1,
          date2: date1,
        )

        expect(result.length).to eq(2) # same meal appears twice in result
        expect(Meal.where(date: date1).count).to eq(original_count)

        meal = Meal.find(same_date_meal.id)
        expect(meal.date).to eq(date1)
        expect(meal.comment).to eq("same date meal")
      end
    end
  end

  describe "atomic swap compatibility" do
    let(:swap_owner) { FactoryBot.create(:user, id_param: "swap-atomic-owner") }
    let(:swap_dish) { FactoryBot.create(:dish, user: swap_owner) }
    let(:first_date) { Date.new(2023, 2, 1) }
    let(:second_date) { Date.new(2023, 2, 2) }
    let(:swap_args) { { user_id: swap_owner.id, date1: first_date, date2: second_date } }

    def make_swap_meal(date, comment)
      FactoryBot.create(:meal, user: swap_owner, dish: swap_dish, date: date, meal_type: 1, comment: comment)
    end

    def make_swap_frame(meal)
      frame = MealFrame.create!(user: swap_owner, name: "swap frame")
      MealFrameEntry.create!(user: swap_owner, meal_frame: frame, date: meal.date, meal_type: meal.meal_type, meal: meal)
    end

    it "preserves return order, class, attributes and related frames on success" do
      first = make_swap_meal(first_date, "first")
      second = make_swap_meal(second_date, "second")
      frames = [make_swap_frame(first), make_swap_frame(second)]
      meal_attributes = [first, second].map { |meal| meal.attributes.slice("user_id", "dish_id", "meal_type", "comment") }
      frame_attributes = frames.map(&:attributes)
      result = described_class.call(**swap_args)
      expect(result.map(&:id)).to eq([first.id, second.id])
      expect(result.map(&:class)).to eq([Business::Food::Meal::Root, Business::Food::Meal::Root])
      expect([first.reload.date, second.reload.date]).to eq([second_date, first_date])
      expect([first, second].map { |meal| meal.attributes.slice("user_id", "dish_id", "meal_type", "comment") }).to eq(meal_attributes)
      expect(frames.map { |frame| frame.reload.attributes }).to eq(frame_attributes)
    end

    it "keeps empty, one-sided and same-day return contracts" do
      expect(described_class.call(**swap_args)).to eq([])
      first = make_swap_meal(first_date, "first")
      expect(described_class.call(**swap_args).map(&:id)).to eq([first.id])
      expect(described_class.call(**swap_args.merge(date1: second_date, date2: second_date)).map(&:id)).to eq([first.id, first.id])
    end

    it "rolls back the first real save when the second save raises the same exception" do
      first = make_swap_meal(first_date, "first")
      second = make_swap_meal(second_date, "second")
      frames = [make_swap_frame(first), make_swap_frame(second)]
      meals_before = [first, second].map(&:attributes)
      frames_before = frames.map(&:attributes)
      failure = RuntimeError.new("second save failed")
      allow(::Meal).to receive(:persist_from_food_meal_root).and_wrap_original do |original, *args|
        if args.first.id == second.id
          expect(first.reload.date).to eq(second_date)
          raise failure
        end
        original.call(*args)
      end
      expect { described_class.call(**swap_args) }.to(raise_error { |error| expect(error).to equal(failure) })
      expect([first, second].map { |meal| meal.reload.attributes }).to eq(meals_before)
      expect(frames.map { |frame| frame.reload.attributes }).to eq(frames_before)
    end
  end
end
