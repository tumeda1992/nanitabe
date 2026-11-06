# frozen_string_literal: true

require "rails_helper"
require_relative "./swap_meals_between_days_command_shared_examples"

module Business::Dish::Meal
  RSpec.describe Command::SwapMealsBetweenDaysCommand do
    describe ".call" do
      before do
        comparer.build_records_for_test()
      end

      context "when swap between day with multi meals and day with multi meals, " do
        let!(:comparer) { COMPARERS[KEY_OF_TEST_SWAP_FROM_DAY_WITH_MEALS_TO_DAY_WITH_MEALS] }

        it "swapping succeeds" do
          described_class.call(
            user_id: comparer.prepared_records[:user_record].id,
            date1: comparer.values[:date1],
            date2: comparer.values[:date2],
          )

          comparer.compare_to_expectation(self)
        end
      end

      context "when swap between day with meal and day without meal, " do
        let!(:comparer) { COMPARERS[KEY_OF_TEST_SWAP_FROM_DAY_WITH_MEAL_TO_DAY_WITHOUT_MEAL] }

        it "swapping succeeds" do
          described_class.call(
            user_id: comparer.prepared_records[:user_record].id,
            date1: comparer.values[:date1],
            date2: comparer.values[:date2],
          )

          comparer.compare_to_expectation(self)
        end
      end

      context "when swap between day without meal and day with meal, " do
        let!(:comparer) { COMPARERS[KEY_OF_TEST_SWAP_FROM_DAY_WITHOUT_MEAL_TO_DAY_WITH_MEAL] }

        it "swapping succeeds" do
          described_class.call(
            user_id: comparer.prepared_records[:user_record].id,
            date1: comparer.values[:date1],
            date2: comparer.values[:date2],
          )

          comparer.compare_to_expectation(self)
        end
      end

      context "when swap between day without meal and day without meal, " do
        let!(:comparer) { COMPARERS[KEY_OF_TEST_SWAP_FROM_DAY_WITHOUT_MEAL_TO_DAY_WITHOUT_MEAL] }

        it "swapping succeeds" do
          described_class.call(
            user_id: comparer.prepared_records[:user_record].id,
            date1: comparer.values[:date1],
            date2: comparer.values[:date2],
          )

          comparer.compare_to_expectation(self)
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
        expect(result.map(&:class)).to eq([Business::Dish::Meal::Meal, Business::Dish::Meal::Meal])
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
        allow(Business::Dish::Meal::Repository).to receive(:update).and_wrap_original do |original, *args|
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
end
