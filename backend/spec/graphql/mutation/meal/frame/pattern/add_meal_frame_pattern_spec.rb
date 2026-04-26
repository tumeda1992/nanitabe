require "rails_helper"
require_relative "../../../../graphql_auth_helper"
require_relative "../../../../../support/factories/user_repository"

module Mutations::Meal::Frame::Pattern
  RSpec.describe AddMealFramePattern, type: :request do
    let(:user_record) { find_or_create_user }
    let!(:meal_frame1) { MealFrame.create!(user: user_record, name: "朝枠") }
    let!(:meal_frame2) { MealFrame.create!(user: user_record, name: "夜枠") }

    def build_mutation
      <<~GRAPHQL
        mutation addMealFramePattern($mealFramePattern: MealFramePatternForCreate!) {
          addMealFramePattern(input: {mealFramePattern: $mealFramePattern}) {
            mealFramePatternId
          }
        }
      GRAPHQL
    end

    context "when add meal frame pattern with no entries" do
      it "adding succeeds and returns meal_frame_pattern_id" do
        variables = {
          mealFramePattern: {
            name: "テストパターン",
            entries: [],
          },
        }
        result = fetch_mutation_with_auth(build_mutation, variables, user_record.id)

        expect(result["addMealFramePattern"]["mealFramePatternId"]).to be_present
        expect(MealFramePattern.last.name).to eq("テストパターン")
      end
    end

    context "when add meal frame pattern with entries" do
      it "creates pattern and entries in single transaction" do
        variables = {
          mealFramePattern: {
            name: "糖質オフ週",
            entries: [
              { dayOffset: 1, mealType: 1, mealFrameId: meal_frame1.id },
              { dayOffset: 1, mealType: 3, mealFrameId: meal_frame2.id },
              { dayOffset: 2, mealType: 3, mealFrameId: meal_frame1.id },
            ],
          },
        }
        result = fetch_mutation_with_auth(build_mutation, variables, user_record.id)

        pattern_id = result["addMealFramePattern"]["mealFramePatternId"]
        expect(pattern_id).to be_present

        pattern = MealFramePattern.find(pattern_id)
        expect(pattern.name).to eq("糖質オフ週")
        expect(pattern.meal_frame_pattern_entries.count).to eq(3)
      end
    end
  end
end
