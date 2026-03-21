require "rails_helper"
require_relative "../../../graphql_auth_helper"
require_relative "../../../../support/factories/user_repository"

module Mutations::Meal::Frame
  RSpec.describe DeleteMealFrame, type: :request do
    let(:user_record) { find_or_create_user }
    let!(:meal_frame) { MealFrame.create!(user: user_record, name: "削除対象の枠") }

    def build_mutation
      <<~GRAPHQL
        mutation deleteMealFrame($id: Int!) {
          deleteMealFrame(input: {id: $id}) {
            mealFrameId
          }
        }
      GRAPHQL
    end

    context "when delete meal frame by graphql with valid params" do
      it "deleting succeeds and returns meal_frame_id" do
        variables = { id: meal_frame.id }
        result = fetch_mutation_with_auth(build_mutation, variables, user_record.id)

        expect(result["deleteMealFrame"]["mealFrameId"]).to eq(meal_frame.id)
        expect(MealFrame.find_by(id: meal_frame.id)).to be_nil
      end
    end
  end
end
