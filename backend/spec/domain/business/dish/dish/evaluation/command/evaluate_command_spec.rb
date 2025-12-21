# frozen_string_literal: true

require "rails_helper"
require_relative "../repository/repository_add_shared_examples"
require_relative "../repository/repository_update_shared_examples"

module Business::Dish::Dish::Evaluation
  RSpec.describe Command::EvaluateCommand do
    describe ".call" do
      before do
        comparer.build_records_for_test()
      end

      context "when evaluate without existing record, " do
        let!(:comparer) { COMPARERS[KEY_OF_TEST_DISH_EVALUATION_SHOULD_BE_CREATED] }

        it "evaluating succeeds" do
          described_class.call(
            user_id: comparer.prepared_records[:user_record].id,
            dish_id: comparer.prepared_records[:dish_record].id,
            **comparer.values,
          )

          comparer.compare_to_expectation(self)
        end
      end

      context "when evaluate with existing record, " do
        let!(:comparer) { COMPARERS[KEY_OF_TEST_DISH_EVALUATION_SHOULD_BE_UPDATED] }

        it "evaluating succeeds" do
          described_class.call(
            user_id: comparer.prepared_records[:user_record].id,
            dish_id: comparer.prepared_records[:dish_record].id,
            **comparer.values,
          )

          comparer.compare_to_expectation(self)
        end
      end
    end
  end
end
