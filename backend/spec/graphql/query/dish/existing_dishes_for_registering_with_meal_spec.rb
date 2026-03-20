require "rails_helper"
require_relative "../../graphql_auth_helper"
require_relative "../../../support/factories/user_repository"
require_relative "../../../support/factories/dish_repository"
require_relative "../../../support/factories/dish_sources_repository"

RSpec.describe "existingDishesForRegisteringWithMeal query - effortLevelMinutes", type: :request do
  let!(:user_record) { find_or_create_user }
  let!(:effort_level) { DishEffortLevel.create!(meal_position: 1, minutes: 10, label: "ぱぱっとできる") }

  # Bullet の AVOID 警告を防ぐため、dish_source を持つ料理を含める
  let!(:dish_source_record) { find_or_create_dish_source }

  let!(:dish_with_effort) do
    dish = FactoryBot.create(:dish, user: user_record, name: "手間設定料理", meal_position: 1, dish_effort_level_id: effort_level.id)
    dish.update!(dish_source: dish_source_record)
    dish
  end

  let!(:dish_without_effort) do
    FactoryBot.create(:dish, user: user_record, name: "手間未設定料理", meal_position: 1)
  end

  def build_query
    <<~GRAPHQL
      query existingDishesForRegisteringWithMeal {
        existingDishesForRegisteringWithMeal {
          id
          name
          effortLevelMinutes
        }
      }
    GRAPHQL
  end

  context "手間レベルが設定されている料理の場合" do
    it "effortLevelMinutesが返ること" do
      data = fetch_mutation_with_auth(build_query, {}, user_record.id)

      dishes = data["existingDishesForRegisteringWithMeal"]
      target = dishes.find { |d| d["id"] == dish_with_effort.id }

      expect(target["effortLevelMinutes"]).to eq(effort_level.minutes)
    end
  end

  context "手間レベルが設定されていない料理の場合" do
    it "effortLevelMinutesがnullで返ること" do
      data = fetch_mutation_with_auth(build_query, {}, user_record.id)

      dishes = data["existingDishesForRegisteringWithMeal"]
      target = dishes.find { |d| d["id"] == dish_without_effort.id }

      expect(target["effortLevelMinutes"]).to be_nil
    end
  end
end
