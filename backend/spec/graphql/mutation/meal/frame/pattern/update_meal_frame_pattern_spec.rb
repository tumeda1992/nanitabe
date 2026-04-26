require "rails_helper"
require_relative "../../../../graphql_auth_helper"
require_relative "../../../../../support/factories/user_repository"

module Mutations::Meal::Frame::Pattern
  RSpec.describe UpdateMealFramePattern, type: :request do
    let(:user_record) { find_or_create_user }
    let!(:meal_frame1) { MealFrame.create!(user: user_record, name: "朝枠") }
    let!(:meal_frame2) { MealFrame.create!(user: user_record, name: "夜枠") }
    let!(:pattern) { MealFramePattern.create!(user: user_record, name: "元のパターン") }
    let!(:existing_entry) {
      MealFramePatternEntry.create!(
        meal_frame_pattern: pattern,
        meal_frame: meal_frame1,
        day_offset: 1,
        meal_type: 1,
      )
    }

    def build_mutation
      <<~GRAPHQL
        mutation updateMealFramePattern($mealFramePattern: MealFramePatternForUpdate!) {
          updateMealFramePattern(input: {mealFramePattern: $mealFramePattern}) {
            mealFramePatternId
          }
        }
      GRAPHQL
    end

    context "when update meal frame pattern with valid params" do
      it "updates name and replaces entries" do
        variables = {
          mealFramePattern: {
            id: pattern.id,
            name: "更新されたパターン",
            entries: [
              { dayOffset: 2, mealType: 3, mealFrameId: meal_frame2.id },
            ],
          },
        }
        result = fetch_mutation_with_auth(build_mutation, variables, user_record.id)

        expect(result["updateMealFramePattern"]["mealFramePatternId"]).to eq(pattern.id)
        expect(pattern.reload.name).to eq("更新されたパターン")
        entries = MealFramePatternEntry.where(meal_frame_pattern_id: pattern.id)
        expect(entries.count).to eq(1)
        expect(entries.first.day_offset).to eq(2)
        expect(entries.first.meal_type).to eq(3)
      end
    end
  end
end
