require "rails_helper"
require_relative "../../../graphql_auth_helper"
require_relative "../../../../support/factories/user_repository"

module Mutations::Meal::Frame
  RSpec.describe UpdateMealFrame, type: :request do
    let(:user_record) { find_or_create_user }
    let!(:meal_frame) { MealFrame.create!(user: user_record, name: "元の枠名") }

    def build_mutation
      <<~GRAPHQL
        mutation updateMealFrame($mealFrame: MealFrameForUpdate!) {
          updateMealFrame(input: {mealFrame: $mealFrame}) {
            mealFrameId
          }
        }
      GRAPHQL
    end

    context "when update meal frame by graphql with valid params" do
      it "updating succeeds and returns meal_frame_id" do
        variables = {
          mealFrame: {
            id: meal_frame.id,
            name: "新しい枠名",
          },
        }
        result = fetch_mutation_with_auth(build_mutation, variables, user_record.id)

        expect(result["updateMealFrame"]["mealFrameId"]).to eq(meal_frame.id)
        expect(meal_frame.reload.name).to eq("新しい枠名")
      end
    end
  end
end
