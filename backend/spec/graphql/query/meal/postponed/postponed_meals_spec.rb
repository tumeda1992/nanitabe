require "rails_helper"
require_relative "../../../graphql_auth_helper"
require_relative "../../../../support/factories/user_repository"
require_relative "../../../../support/factories/dish_repository"

RSpec.describe "postponedMeals query", type: :request do
  let!(:user_record) { find_or_create_user }
  let!(:dish_record) { find_or_create_dish }

  def build_query
    <<~GRAPHQL
      query postponedMeals {
        postponedMeals {
          id
          dishId
          dishName
          mealType
          comment
          createdAt
        }
      }
    GRAPHQL
  end

  context "when the user has postponed meals" do
    let!(:older_postponed_meal) do
      record = PostponedMeal.create!(user: user_record, dish: dish_record, meal_type: 3)
      record.update_column(:created_at, 2.days.ago)
      record
    end
    let!(:newer_postponed_meal) do
      record = PostponedMeal.create!(user: user_record, dish: dish_record, meal_type: 2, comment: "急遽外食")
      record.update_column(:created_at, 1.day.ago)
      record
    end

    it "returns postponed meals ordered by createdAt desc" do
      data = fetch_mutation_with_auth(build_query, {}, user_record.id)

      ids = data["postponedMeals"].map { |row| row["id"] }
      expect(ids).to eq([newer_postponed_meal.id, older_postponed_meal.id])

      first = data["postponedMeals"].first
      expect(first["dishId"]).to eq(dish_record.id)
      expect(first["dishName"]).to eq(dish_record.name)
      expect(first["mealType"]).to eq(2)
      expect(first["comment"]).to eq("急遽外食")

      second = data["postponedMeals"].second
      expect(second["comment"]).to be_nil
    end
  end

  context "when another user has postponed meals" do
    let(:other_user) { User.create!(id_param: "other_user_param_query") }
    let!(:other_postponed_meal) do
      PostponedMeal.create!(user: other_user, dish: dish_record, meal_type: 1)
    end

    it "does not include other users' postponed meals" do
      data = fetch_mutation_with_auth(build_query, {}, user_record.id)

      expect(data["postponedMeals"]).to eq([])
    end
  end

  context "when the user has no postponed meals" do
    it "returns an empty array" do
      data = fetch_mutation_with_auth(build_query, {}, user_record.id)

      expect(data["postponedMeals"]).to eq([])
    end
  end
end
