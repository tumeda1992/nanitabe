require "rails_helper"
require_relative "../../graphql_auth_helper"
require_relative "../../../support/factories/user_repository"
require_relative "../../../support/factories/dish_repository"

RSpec.describe "updateDish with dishEffortLevelId", type: :request do
  let!(:user_record) { find_or_create_user }
  let!(:existing_dish_record) { find_or_create_dish }
  let!(:effort_level) { DishEffortLevel.create!(meal_position: 1, minutes: 10, label: "ぱぱっとできる") }
  let!(:effort_level2) { DishEffortLevel.create!(meal_position: 1, minutes: 20, label: "普通") }

  before do
    allow(Business::Food::Dish::Word::Usecase::Normalizer)
      .to receive(:call)
      .and_return("normalized")
  end

  def build_mutation
    <<~GRAPHQL
      mutation updateDish(
        $dish: DishForUpdate!
        $dishSourceRelation: DishSourceRelationForUpdate
      ) {
        updateDish(input: {
          dish: $dish
          dishSourceRelation: $dishSourceRelation
        }) {
          dishId
        }
      }
    GRAPHQL
  end

  context "dishEffortLevelIdを指定した場合" do
    it "dish_effort_level_idが更新されること" do
      variables = {
        dish: {
          id: existing_dish_record.id,
          dishEffortLevelId: effort_level.id,
        },
        dishSourceRelation: nil,
      }

      fetch_mutation_with_auth(build_mutation, variables, user_record.id)

      updated_dish = ::Dish.find(existing_dish_record.id)
      expect(updated_dish.dish_effort_level_id).to eq(effort_level.id)
    end
  end

  context "dishEffortLevelIdをnullで更新した場合" do
    before do
      existing_dish_record.update!(dish_effort_level_id: effort_level2.id)
    end

    it "dish_effort_level_idがnilになること" do
      variables = {
        dish: {
          id: existing_dish_record.id,
          dishEffortLevelId: nil,
        },
        dishSourceRelation: nil,
      }

      fetch_mutation_with_auth(build_mutation, variables, user_record.id)

      updated_dish = ::Dish.find(existing_dish_record.id)
      expect(updated_dish.dish_effort_level_id).to be_nil
    end
  end
end
