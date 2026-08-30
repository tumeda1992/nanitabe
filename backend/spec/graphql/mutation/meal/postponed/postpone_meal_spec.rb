require "rails_helper"
require_relative "../../../graphql_auth_helper"
require_relative "../../../../support/factories/user_repository"
require_relative "../../../../support/factories/dish_repository"

module Mutations::Meal::Postponed
  RSpec.describe PostponeMeal, type: :request do
    let(:user_record) { find_or_create_user }
    let(:dish_record) { find_or_create_dish }
    let!(:meal_record) do
      Meal.create!(user: user_record, dish: dish_record, date: Date.today, meal_type: 3, comment: "急遽外食")
    end

    def build_mutation
      <<~GRAPHQL
        mutation postponeMeal($mealId: Int!) {
          postponeMeal(input: { mealId: $mealId }) {
            postponedMealId
          }
        }
      GRAPHQL
    end

    context "when postponing a meal that is not linked to a frame entry" do
      it "deletes the meal and creates a postponed meal in one transaction" do
        variables = { mealId: meal_record.id }

        expect {
          fetch_mutation_with_auth(build_mutation, variables, user_record.id)
        }.to change { Meal.count }.by(-1).and change { PostponedMeal.count }.by(1)

        postponed_meal_record = PostponedMeal.last
        expect(postponed_meal_record.user_id).to eq(user_record.id)
        expect(postponed_meal_record.dish_id).to eq(dish_record.id)
        expect(postponed_meal_record.meal_type).to eq(3)
        expect(postponed_meal_record.comment).to eq("急遽外食")
        expect(Meal.exists?(meal_record.id)).to be(false)
      end
    end

    context "when the meal has no comment" do
      let!(:meal_record) do
        Meal.create!(user: user_record, dish: dish_record, date: Date.today, meal_type: 3, comment: nil)
      end

      it "creates a postponed meal with a NULL comment" do
        variables = { mealId: meal_record.id }

        fetch_mutation_with_auth(build_mutation, variables, user_record.id)

        expect(PostponedMeal.last.comment).to be_nil
      end
    end

    context "when the meal is linked to a meal frame entry" do
      let!(:meal_frame) { MealFrame.create!(user: user_record, name: "テスト枠") }
      let!(:meal_frame_entry) do
        MealFrameEntry.create!(
          user: user_record,
          meal_frame: meal_frame,
          date: meal_record.date,
          meal_type: meal_record.meal_type,
          meal: meal_record,
        )
      end

      it "nullifies the meal_frame_entry's meal_id instead of deleting it" do
        variables = { mealId: meal_record.id }

        fetch_mutation_with_auth(build_mutation, variables, user_record.id)

        expect(meal_frame_entry.reload.meal_id).to be_nil
        expect(MealFrameEntry.exists?(meal_frame_entry.id)).to be(true)
      end
    end

    context "when meal_id belongs to another user" do
      let(:other_user) { User.create!(id_param: "other_user_param_postpone") }

      it "raises an error and does not change any records" do
        variables = { mealId: meal_record.id }

        expect {
          expect do
            fetch_mutation_with_auth(build_mutation, variables, other_user.id)
          end.to raise_error(RuntimeError)
        }.to change { Meal.count }.by(0).and change { PostponedMeal.count }.by(0)
      end
    end
  end
end
