# frozen_string_literal: true

require "rails_helper"
require_relative "./repository_add_shared_examples"

module Business::Dish::Dish::Evaluation
  RSpec.describe Repository do
    describe ".add" do
      before do
        comparer.build_records_for_test()

        @dish_evaluation = Evaluation.new(
          user_id: comparer.prepared_records[:user_record].id,
          dish_id: comparer.prepared_records[:dish_record].id,
          **comparer.values,
        )
      end

      context "when add dish evaluation with required fields," do
        let!(:comparer) { COMPARERS[KEY_OF_TEST_DISH_EVALUATION_SHOULD_BE_CREATED] }

        it "adding succeeds" do
          described_class.add(@dish_evaluation)

          comparer.compare_to_expectation(self)
        end
      end
    end
  end
end
