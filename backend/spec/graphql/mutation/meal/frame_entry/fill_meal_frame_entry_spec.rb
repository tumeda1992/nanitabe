require "rails_helper"
require_relative "../../../graphql_auth_helper"
require_relative "../../../../support/factories/user_repository"
require_relative "../../../../support/factories/meal_repository"

module Mutations::Meal::FrameEntry
  RSpec.describe FillMealFrameEntry, type: :request do
    let(:user_record) { find_or_create_user }
    let!(:meal_frame) { MealFrame.create!(user: user_record, name: "テスト枠") }
    let!(:meal_frame_entry) do
      MealFrameEntry.create!(
        user: user_record,
        meal_frame: meal_frame,
        date: Date.today,
        meal_type: 3,
      )
    end
    let!(:meal) { find_or_create_meal }

    def build_mutation
      <<~GRAPHQL
        mutation fillMealFrameEntry($frameEntryId: Int!, $mealId: Int!) {
          fillMealFrameEntry(input: { frameEntryId: $frameEntryId, mealId: $mealId }) {
            frameEntryId
          }
        }
      GRAPHQL
    end

    context "when fill meal frame entry with valid params" do
      it "filling succeeds and meal_id is set" do
        variables = { frameEntryId: meal_frame_entry.id, mealId: meal.id }
        result = fetch_mutation_with_auth(build_mutation, variables, user_record.id)

        expect(result["fillMealFrameEntry"]["frameEntryId"]).to eq(meal_frame_entry.id)
        updated_record = MealFrameEntry.find(meal_frame_entry.id)
        expect(updated_record.meal_id).to eq(meal.id)
      end
    end

    context "when frame_entry_id belongs to another user" do
      let(:other_user) { User.create!(id_param: "other_user_param_fill") }
      let!(:other_meal_frame) { MealFrame.create!(user: other_user, name: "他ユーザー枠") }
      let!(:other_meal_frame_entry) do
        MealFrameEntry.create!(
          user: other_user,
          meal_frame: other_meal_frame,
          date: Date.today,
          meal_type: 1,
        )
      end

      it "raises an error" do
        variables = { frameEntryId: other_meal_frame_entry.id, mealId: meal.id }
        expect do
          fetch_mutation_with_auth(build_mutation, variables, user_record.id)
        end.to raise_error(RuntimeError)
      end
    end

    context "when meal_id belongs to another user" do
      let(:other_user) { User.create!(id_param: "other_user_param_fill2") }
      let!(:other_meal) { FactoryBot.create(:meal, user: other_user, dish: FactoryBot.create(:dish, user: other_user)) }

      it "raises an error when meal_id does not belong to the user" do
        variables = { frameEntryId: meal_frame_entry.id, mealId: other_meal.id }
        headers = fetch_auth_header_values(existing_user_id: user_record.id)
        post("/graphql", params: { query: build_mutation, variables: variables }, as: :json, headers: headers)
        expect(response).to have_http_status(:not_found)
        expect(meal_frame_entry.reload.meal_id).to be_nil
      end
    end
  end
end
