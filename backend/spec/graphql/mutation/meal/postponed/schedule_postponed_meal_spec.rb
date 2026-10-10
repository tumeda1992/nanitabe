require "rails_helper"
require_relative "../../../graphql_auth_helper"
require_relative "../../../../support/factories/user_repository"
require_relative "../../../../support/factories/dish_repository"

module Mutations::Meal::Postponed
  RSpec.describe SchedulePostponedMeal, type: :request do
    let(:user_record) { find_or_create_user }
    let(:dish_record) { find_or_create_dish }
    let!(:postponed_meal_record) do
      PostponedMeal.create!(user: user_record, dish: dish_record, meal_type: 3)
    end

    def build_mutation
      <<~GRAPHQL
        mutation schedulePostponedMeal($postponedMealId: Int!, $date: ISO8601Date!) {
          schedulePostponedMeal(input: { postponedMealId: $postponedMealId, date: $date }) {
            mealId
          }
        }
      GRAPHQL
    end

    context "when postponedMealId exists and has no comment" do
      it "creates a meal inheriting meal_type with a NULL comment and removes the postponed meal" do
        variables = { postponedMealId: postponed_meal_record.id, date: "2026-09-01" }

        expect {
          fetch_mutation_with_auth(build_mutation, variables, user_record.id)
        }.to change { Meal.count }.by(1).and change { PostponedMeal.count }.by(-1)

        created_meal = Meal.last
        expect(created_meal.dish_id).to eq(dish_record.id)
        expect(created_meal.meal_type).to eq(3)
        expect(created_meal.date).to eq(Date.parse("2026-09-01"))
        expect(created_meal.comment).to be_nil
        expect(PostponedMeal.exists?(postponed_meal_record.id)).to be(false)
      end
    end

    context "when postponedMealId exists and has a comment" do
      let!(:postponed_meal_record) do
        PostponedMeal.create!(user: user_record, dish: dish_record, meal_type: 3, comment: "急遽外食")
      end

      it "restores the comment onto the newly created meal" do
        variables = { postponedMealId: postponed_meal_record.id, date: "2026-09-01" }

        fetch_mutation_with_auth(build_mutation, variables, user_record.id)

        expect(Meal.last.comment).to eq("急遽外食")
      end
    end

    context "when postponedMealId does not exist" do
      it "raises an error and rolls back without creating a Meal" do
        variables = { postponedMealId: 99_999, date: "2026-09-01" }

        expect {
          expect do
            fetch_mutation_with_auth(build_mutation, variables, user_record.id)
          end.to raise_error(RuntimeError)
        }.to change { Meal.count }.by(0).and change { PostponedMeal.count }.by(0)
      end
    end

    context "when postponedMealId belongs to another user" do
      let(:other_user) { User.create!(id_param: "other_user_param_schedule") }

      it "raises an error and does not create a Meal" do
        variables = { postponedMealId: postponed_meal_record.id, date: "2026-09-01" }

        expect {
          expect do
            fetch_mutation_with_auth(build_mutation, variables, other_user.id)
          end.to raise_error(RuntimeError)
        }.to change { Meal.count }.by(0).and change { PostponedMeal.count }.by(0)
      end
    end
  end
end
