require "rails_helper"
require_relative "../../graphql_auth_helper"
require_relative "../../../domain/business/dish/meal/repository/repository_add_shared_examples"
require_relative "../../../domain/business/dish/dish/repository/repository_add_shared_examples"
require_relative "../../../domain/business/dish/dish/repository/repository_put_dish_relation_shared_examples"
require_relative "../../../domain/business/dish/dish/tag/repository/repository_add_shared_examples"

module Mutations::Meal
  RSpec.describe AddMealWithNewDishAndNewSource, type: :request do
    def build_mutation
      <<~GRAPHQL
        mutation addMealWithNewDish(
          $dish: DishForCreate!
          $dishSource: SourceForRead!
          $dishSourceRelationDetail: DishSourceRelationDetail
          $dishTags: [Tag!]
          $meal: MealForCreate!
        ) {
          addMealWithNewDish(input: {
            dish: $dish
            dishSource: $dishSource
            dishSourceRelationDetail: $dishSourceRelationDetail
            dishTags: $dishTags
            meal: $meal
          }
        ) {
            mealId
            dishId
          }
        }
      GRAPHQL
    end

    def build_mutation_with_frame_entry_id
      <<~GRAPHQL
        mutation addMealWithNewDish(
          $dish: DishForCreate!
          $dishSource: SourceForRead!
          $dishSourceRelationDetail: DishSourceRelationDetail
          $dishTags: [Tag!]
          $meal: MealForCreate!
          $frameEntryId: Int
        ) {
          addMealWithNewDish(input: {
            dish: $dish
            dishSource: $dishSource
            dishSourceRelationDetail: $dishSourceRelationDetail
            dishTags: $dishTags
            meal: $meal
            frameEntryId: $frameEntryId
          }
        ) {
            mealId
            dishId
          }
        }
      GRAPHQL
    end

    before do
      dish_comparer.build_records_for_test()
      dish_source_relation_comparer.build_records_for_test()
      meal_comparer.build_records_for_test()
      dish_tag_comparer.build_records_for_test()
    end

    context "when add meal and dish by graphql with full params for architecture communication confirmation, " do
      let!(:dish_comparer) { COMPARERS[KEY_OF_TEST_DISH_SHOULD_BE_CREATED_WITH_FULL_VALUES] }
      let!(:dish_source_relation_comparer) { COMPARERS[KEY_OF_TEST_DISH_SOURCE_RELATION_SHOULD_BE_CREATED] }
      let!(:dish_tag_comparer) { COMPARERS[KEY_OF_TEST_DISH_TAG_SHOULD_BE_CREATED] }
      let!(:meal_comparer) { COMPARERS[KEY_OF_TEST_MEAL_SHOULD_BE_CREATED_WITH_FULL_FIELD] }

      it "adding succeeds" do
        variables = {
          dish: {
            name: dish_comparer.values[:name],
            mealPosition: dish_comparer.values[:meal_position],
            comment: dish_comparer.values[:comment],
          },
          dishSource: {
            id: dish_source_relation_comparer.prepared_records[:dish_source_record].id,
            type: dish_source_relation_comparer.prepared_records[:dish_source_record].type,
          },
          dishSourceRelationDetail: {
            recipeBookPage: dish_source_relation_comparer.values[:recipe_book_page],
          },
          dishTags: [
            {
              content: dish_tag_comparer.values[:content],
            },
          ],
          meal: {
            date: meal_comparer.values[:date],
            mealType: meal_comparer.values[:meal_type],
            comment: meal_comparer.values[:comment],
          },
        }
        response = fetch_mutation_with_auth(build_mutation, variables, meal_comparer.prepared_records[:user_record].id)

        created_dish_id = response["addMealWithNewDish"]["dishId"]
        dish_comparer.compare_to_expectation(self)
        dish_source_relation_comparer.compare_to_expectation(self, dish_id: created_dish_id)
        dish_tag_comparer.compare_to_expectation(self, dish_id: created_dish_id)
        meal_comparer.compare_to_expectation(self, dish_id: created_dish_id)
      end
    end

    context "when frame_entry_id is given" do
      let!(:dish_comparer) { COMPARERS[KEY_OF_TEST_DISH_SHOULD_BE_CREATED_WITH_FULL_VALUES] }
      let!(:dish_source_relation_comparer) { COMPARERS[KEY_OF_TEST_DISH_SOURCE_RELATION_SHOULD_BE_CREATED] }
      let!(:dish_tag_comparer) { COMPARERS[KEY_OF_TEST_DISH_TAG_SHOULD_BE_CREATED] }
      let!(:meal_comparer) { COMPARERS[KEY_OF_TEST_MEAL_SHOULD_BE_CREATED_WITH_FULL_FIELD] }
      let!(:user_record) { meal_comparer.prepared_records[:user_record] }
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
          dish: {
            name: dish_comparer.values[:name],
            mealPosition: dish_comparer.values[:meal_position],
            comment: dish_comparer.values[:comment],
          },
          dishSource: {
            id: dish_source_relation_comparer.prepared_records[:dish_source_record].id,
            type: dish_source_relation_comparer.prepared_records[:dish_source_record].type,
          },
          dishSourceRelationDetail: {
            recipeBookPage: dish_source_relation_comparer.values[:recipe_book_page],
          },
          dishTags: [
            {
              content: dish_tag_comparer.values[:content],
            },
          ],
          meal: {
            date: meal_comparer.values[:date],
            mealType: meal_comparer.values[:meal_type],
            comment: meal_comparer.values[:comment],
          },
          frameEntryId: meal_frame_entry.id,
        }
        response = fetch_mutation_with_auth(
          build_mutation_with_frame_entry_id,
          variables,
          user_record.id,
        )

        created_meal_id = response["addMealWithNewDish"]["mealId"]
        expect(MealFrameEntry.find(meal_frame_entry.id).meal_id).to eq(created_meal_id)
      end
    end
  end
end
