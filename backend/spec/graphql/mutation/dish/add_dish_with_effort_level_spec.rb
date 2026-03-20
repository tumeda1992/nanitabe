require "rails_helper"
require_relative "../../graphql_auth_helper"
require_relative "../../../support/factories/user_repository"

RSpec.describe "addDish with dishEffortLevelId", type: :request do
  let!(:user_record) { find_or_create_user }
  let!(:effort_level) { DishEffortLevel.create!(meal_position: 1, minutes: 10, label: "ぱぱっとできる") }

  def build_mutation
    <<~GRAPHQL
      mutation addDish(
        $dish: DishForCreate!
      ) {
        addDish(input: {
          dish: $dish
        }) {
          dishId
        }
      }
    GRAPHQL
  end

  context "dishEffortLevelIdを指定した場合" do
    it "dish_effort_level_idが保存されること" do
      variables = {
        dish: {
          name: "テスト料理",
          mealPosition: 1,
          dishEffortLevelId: effort_level.id,
        },
      }

      data = fetch_mutation_with_auth(build_mutation, variables, user_record.id)

      dish_id = data["addDish"]["dishId"]
      created_dish = ::Dish.find(dish_id)
      expect(created_dish.dish_effort_level_id).to eq(effort_level.id)
    end
  end

  context "dishEffortLevelIdを指定しない場合" do
    it "dish_effort_level_idがnilで保存されること" do
      variables = {
        dish: {
          name: "テスト料理",
          mealPosition: 1,
        },
      }

      data = fetch_mutation_with_auth(build_mutation, variables, user_record.id)

      dish_id = data["addDish"]["dishId"]
      created_dish = ::Dish.find(dish_id)
      expect(created_dish.dish_effort_level_id).to be_nil
    end
  end
end
