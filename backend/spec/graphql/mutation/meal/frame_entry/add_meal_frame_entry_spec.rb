require "rails_helper"
require_relative "../../../graphql_auth_helper"
require_relative "../../../../support/factories/user_repository"

module Mutations::Meal::FrameEntry
  RSpec.describe AddMealFrameEntry, type: :request do
    let(:user_record) { find_or_create_user }
    let!(:meal_frame) { MealFrame.create!(user: user_record, name: "週末枠") }

    def build_mutation
      <<~GRAPHQL
        mutation addMealFrameEntry($mealFrameEntry: MealFrameEntryForCreate!) {
          addMealFrameEntry(input: {mealFrameEntry: $mealFrameEntry}) {
            mealFrameEntryId
          }
        }
      GRAPHQL
    end

    context "when add meal frame entry by graphql with valid params" do
      it "adding succeeds and returns meal_frame_entry_id" do
        variables = {
          mealFrameEntry: {
            mealFrameId: meal_frame.id,
            date: Date.today.to_s,
            mealType: 1,
          },
        }
        result = fetch_mutation_with_auth(build_mutation, variables, user_record.id)

        expect(result["addMealFrameEntry"]["mealFrameEntryId"]).to be_present
        expect(MealFrameEntry.last.meal_frame_id).to eq(meal_frame.id)
      end
    end
  end
end
