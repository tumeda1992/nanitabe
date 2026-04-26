require "rails_helper"
require_relative "../../../../graphql_auth_helper"
require_relative "../../../../../support/factories/user_repository"

module Mutations::Meal::Frame::Pattern
  RSpec.describe DeleteMealFramePattern, type: :request do
    let(:user_record) { find_or_create_user }
    let!(:meal_frame) { MealFrame.create!(user: user_record, name: "テスト枠") }
    let!(:pattern) { MealFramePattern.create!(user: user_record, name: "削除対象パターン") }
    let!(:entry) {
      MealFramePatternEntry.create!(
        meal_frame_pattern: pattern,
        meal_frame: meal_frame,
        day_offset: 1,
        meal_type: 1,
      )
    }

    def build_mutation
      <<~GRAPHQL
        mutation deleteMealFramePattern($id: Int!) {
          deleteMealFramePattern(input: {id: $id}) {
            mealFramePatternId
          }
        }
      GRAPHQL
    end

    context "when delete meal frame pattern with valid params" do
      it "deletes the pattern and returns id" do
        variables = { id: pattern.id }
        result = fetch_mutation_with_auth(build_mutation, variables, user_record.id)

        expect(result["deleteMealFramePattern"]["mealFramePatternId"]).to eq(pattern.id)
        expect(MealFramePattern.find_by(id: pattern.id)).to be_nil
        expect(MealFramePatternEntry.find_by(id: entry.id)).to be_nil
      end
    end
  end
end
