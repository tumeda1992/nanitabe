require "rails_helper"
require_relative "../../../graphql_auth_helper"
require_relative "../../../../support/factories/user_repository"

module Mutations::Meal::FrameEntry
  RSpec.describe RemoveMealFrameEntry, type: :request do
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

    def build_mutation
      <<~GRAPHQL
        mutation removeMealFrameEntry($id: Int!) {
          removeMealFrameEntry(input: {id: $id}) {
            mealFrameEntryId
          }
        }
      GRAPHQL
    end

    context "when remove meal frame entry by graphql with valid params" do
      it "removing succeeds and returns meal_frame_entry_id" do
        variables = { id: meal_frame_entry.id }
        result = fetch_mutation_with_auth(build_mutation, variables, user_record.id)

        expect(result["removeMealFrameEntry"]["mealFrameEntryId"]).to eq(meal_frame_entry.id)
        expect(MealFrameEntry.find_by(id: meal_frame_entry.id)).to be_nil
      end
    end
  end
end
