# frozen_string_literal: true

require "rails_helper"
require_relative "./repository_update_shared_examples"

module Business::Dish::Dish::Evaluation
  RSpec.describe Repository do
    describe ".update" do
      before do
        comparer.build_records_for_test()

        @updated_dish_evaluation = Repository.find(
          comparer.prepared_records[:dish_evaluation_record].id,
        )
        @updated_dish_evaluation.assign_attributes(**comparer.values)
      end

      context "when update dish evaluation with required fields," do
        let!(:comparer) { COMPARERS[KEY_OF_TEST_DISH_EVALUATION_SHOULD_BE_UPDATED] }

        it "updating succeeds" do
          described_class.update(@updated_dish_evaluation, comparer.prepared_records[:user_record].id)

          comparer.compare_to_expectation(self)
        end
      end
    end
  end
end
