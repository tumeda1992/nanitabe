require "rails_helper"
require_relative "../../graphql_auth_helper"
require_relative "../../../domain/business/dish/meal/repository/repository_add_shared_examples"
require_relative "../../../support/factories/user_repository"

module Mutations::Meal
  RSpec.describe AddMeal, type: :request do
    def build_mutation
      <<~GRAPHQL
        mutation addMeal($dishId: Int!, $meal: MealForCreate!) {
          addMeal(input: {dishId: $dishId, meal: $meal}) {
            mealId
          }
        }
      GRAPHQL
    end

    def build_mutation_with_frame_entry_id
      <<~GRAPHQL
        mutation addMeal($dishId: Int!, $meal: MealForCreate!, $frameEntryId: Int) {
          addMeal(input: {dishId: $dishId, meal: $meal, frameEntryId: $frameEntryId}) {
            mealId
          }
        }
      GRAPHQL
    end

    before do
      comparer.build_records_for_test()
    end

    context "when add meal by graphql with full params for architecture communication confirmation, " do
      let!(:comparer) { COMPARERS[KEY_OF_TEST_MEAL_SHOULD_BE_CREATED_WITH_FULL_FIELD] }

      it "adding succeeds" do
        variables = {
          dishId: comparer.prepared_records[:dish_record].id,
          meal: {
            date: comparer.values[:date],
            mealType: comparer.values[:meal_type],
            comment: comparer.values[:comment],
          },
        }
        fetch_mutation_with_auth(build_mutation, variables, comparer.prepared_records[:user_record].id)

        comparer.compare_to_expectation(self)
      end
    end

    context "when frame_entry_id is given" do
      let!(:comparer) { COMPARERS[KEY_OF_TEST_MEAL_SHOULD_BE_CREATED_WITH_FULL_FIELD] }
      let!(:user_record) { comparer.prepared_records[:user_record] }
      let!(:meal_frame) { MealFrame.create!(user: user_record, name: "パスタ枠") }
      let!(:meal_frame_entry) do
        MealFrameEntry.create!(
          user: user_record,
          meal_frame: meal_frame,
          date: Date.new(2026, 3, 25),
          meal_type: 2,
        )
      end

      it "sets meal_id on the meal_frame_entry" do
        variables = {
          dishId: comparer.prepared_records[:dish_record].id,
          meal: {
            date: comparer.values[:date],
            mealType: comparer.values[:meal_type],
            comment: comparer.values[:comment],
          },
          frameEntryId: meal_frame_entry.id,
        }
        response = fetch_mutation_with_auth(
          build_mutation_with_frame_entry_id,
          variables,
          user_record.id,
        )

        created_meal_id = response["addMeal"]["mealId"]
        expect(MealFrameEntry.find(meal_frame_entry.id).meal_id).to eq(created_meal_id)
      end
    end
  end
end
