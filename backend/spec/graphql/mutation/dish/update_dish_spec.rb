require "rails_helper"
require_relative "../../graphql_auth_helper"
require_relative "../../../domain/business/dish/dish/repository/repository_update_shared_examples"
require_relative "../../../domain/business/dish/dish/repository/repository_put_dish_relation_shared_examples"
require_relative "../../../domain/business/dish/dish/tag/repository/repository_add_shared_examples"

module Mutations::Dish
  RSpec.describe UpdateDish, type: :request do
    def build_mutation
      <<~GRAPHQL
        mutation updateDish(
          $dish: DishForUpdate!
          $dishSourceRelation: DishSourceRelationForUpdate
          $dishTags: [Tag!]
        ) {
          updateDish(input: {
            dish: $dish
            dishSourceRelation: $dishSourceRelation
            dishTags: $dishTags
          }
        ) {
            dishId
          }
        }
      GRAPHQL
    end

    before do
      dish_comparer.build_records_for_test()
      dish_source_relation_comparer.build_records_for_test()
      dish_tag_comparer.build_records_for_test()
    end

    context "when update dish by graphql with full params for architecture communication confirmation, " do
      let!(:dish_comparer) { COMPARERS[KEY_OF_TEST_DISH_SHOULD_BE_UPDATED_WITH_FULL_FIELD] }
      let!(:dish_source_relation_comparer) { COMPARERS[KEY_OF_TEST_DISH_SOURCE_RELATION_SHOULD_BE_UPDATED] }
      let!(:dish_tag_comparer) { COMPARERS[KEY_OF_TEST_DISH_TAG_SHOULD_BE_CREATED] }

      it "updating succeeds" do
        variables = {
          dish: {
            id: dish_comparer.prepared_records[:dish_record].id,
            name: dish_comparer.values[:name],
            mealPosition: dish_comparer.values[:meal_position],
            comment: dish_comparer.values[:comment],
          },
          dishSourceRelation: {
            dishId: dish_comparer.prepared_records[:dish_record].id,
            dishSourceId: dish_source_relation_comparer.prepared_records[:dish_source_relation_record].dish_source_id,
            dishSourceType: dish_source_relation_comparer.prepared_records[:dish_source_record].type,
            dishSourceRelationDetail: {
              recipeBookPage: dish_source_relation_comparer.values[:recipe_book_page],
            },
          },
          dishTags: [
            {
              content: dish_tag_comparer.values[:content],
            },
          ],
        }

        fetch_mutation_with_auth(build_mutation, variables, dish_comparer.prepared_records[:user_record].id)

        dish_comparer.compare_to_expectation(self)
        dish_source_relation_comparer.compare_to_expectation(self)
        dish_tag_comparer.compare_to_expectation(self, dish_id: dish_comparer.prepared_records[:dish_record].id)
      end
    end
  end
end
