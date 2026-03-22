require "rails_helper"
require_relative "../../../graphql_auth_helper"
require_relative "../../../../support/factories/user_repository"

module Mutations::Meal::Frame
  RSpec.describe AddMealFrame, type: :request do
    let(:user_record) { find_or_create_user }

    def build_mutation
      <<~GRAPHQL
        mutation addMealFrame($mealFrame: MealFrameForCreate!) {
          addMealFrame(input: {mealFrame: $mealFrame}) {
            mealFrameId
          }
        }
      GRAPHQL
    end

    context "when add meal frame by graphql with valid params" do
      it "adding succeeds and returns meal_frame_id" do
        variables = {
          mealFrame: {
            name: "週末枠",
          },
        }
        result = fetch_mutation_with_auth(build_mutation, variables, user_record.id)

        expect(result["addMealFrame"]["mealFrameId"]).to be_present
        expect(MealFrame.last.name).to eq("週末枠")
      end
    end
  end
end
