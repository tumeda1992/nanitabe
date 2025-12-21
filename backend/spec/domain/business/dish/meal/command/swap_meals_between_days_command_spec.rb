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
  end
end
