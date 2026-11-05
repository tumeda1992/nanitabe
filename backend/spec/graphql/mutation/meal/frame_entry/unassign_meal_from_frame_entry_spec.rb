require "rails_helper"
require_relative "../../../graphql_auth_helper"
require_relative "../../../../support/factories/user_repository"
require_relative "../../../../support/factories/meal_repository"

module Mutations::Meal::FrameEntry
  RSpec.describe UnassignMealFromFrameEntry, type: :request do
    let(:user_record) { find_or_create_user }
    let!(:meal_frame) { MealFrame.create!(user: user_record, name: "テスト枠") }
    let!(:meal) { find_or_create_meal }
    let!(:meal_frame_entry) do
      MealFrameEntry.create!(
        user: user_record,
        meal_frame: meal_frame,
        date: Date.today,
        meal_type: 3,
        meal: meal,
      )
    end

    def build_mutation
      <<~GRAPHQL
        mutation unassignMealFromFrameEntry($frameEntryId: Int!) {
          unassignMealFromFrameEntry(input: { frameEntryId: $frameEntryId }) {
            frameEntryId
          }
        }
      GRAPHQL
    end

    context "when unassign meal from frame entry with valid params" do
      it "unassigning succeeds and meal_id becomes nil" do
        variables = { frameEntryId: meal_frame_entry.id }
        result = fetch_mutation_with_auth(build_mutation, variables, user_record.id)

        expect(result["unassignMealFromFrameEntry"]["frameEntryId"]).to eq(meal_frame_entry.id)
        updated_record = MealFrameEntry.find(meal_frame_entry.id)
        expect(updated_record.meal_id).to be_nil
      end
    end

    context "when frame_entry_id belongs to another user" do
      let(:other_user) { User.create!(id_param: "other_user_param") }
      let!(:other_meal_frame) { MealFrame.create!(user: other_user, name: "他ユーザー枠") }
      let!(:other_meal_frame_entry) do
        MealFrameEntry.create!(
          user: other_user,
          meal_frame: other_meal_frame,
          date: Date.today,
          meal_type: 1,
          meal: meal,
        )
      end

      it "raises an error" do
        variables = { frameEntryId: other_meal_frame_entry.id }
        expect do
          fetch_mutation_with_auth(build_mutation, variables, user_record.id)
        end.to raise_error(RuntimeError)
      end
    end
  end
end
