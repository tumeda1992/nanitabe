require "rails_helper"
require_relative "../../../../graphql_auth_helper"
require_relative "../../../../../support/factories/user_repository"

RSpec.describe "mealFramePatterns query", type: :request do
  let!(:user_record) { find_or_create_user }
  let!(:meal_frame) { MealFrame.create!(user: user_record, name: "テスト枠") }

  def build_query
    <<~GRAPHQL
      query mealFramePatterns {
        mealFramePatterns {
          id
          name
          entries {
            id
            dayOffset
            mealType
            mealFrameId
            mealFrameName
          }
        }
      }
    GRAPHQL
  end

  context "when user has patterns" do
    let!(:pattern1) { MealFramePattern.create!(user: user_record, name: "パターン1") }
    let!(:pattern2) { MealFramePattern.create!(user: user_record, name: "パターン2") }
    let!(:entry) {
      MealFramePatternEntry.create!(
        meal_frame_pattern: pattern1,
        meal_frame: meal_frame,
        day_offset: 1,
        meal_type: 1,
      )
    }

    it "returns all patterns for the user with entries" do
      data = fetch_mutation_with_auth(build_query, {}, user_record.id)

      patterns = data["mealFramePatterns"]
      expect(patterns.length).to eq(2)

      pattern1_data = patterns.find { |p| p["name"] == "パターン1" }
      expect(pattern1_data).to be_present
      expect(pattern1_data["entries"].length).to eq(1)
      expect(pattern1_data["entries"][0]["dayOffset"]).to eq(1)
      expect(pattern1_data["entries"][0]["mealType"]).to eq(1)
      expect(pattern1_data["entries"][0]["mealFrameName"]).to eq("テスト枠")
    end
  end

  context "when user has no patterns" do
    it "returns empty array" do
      data = fetch_mutation_with_auth(build_query, {}, user_record.id)

      expect(data["mealFramePatterns"]).to eq([])
    end
  end

  context "when another user has patterns" do
    let!(:other_user) { User.create!(id_param: "other_user_xxx") }
    let!(:other_pattern) { MealFramePattern.create!(user: other_user, name: "他ユーザーのパターン") }

    it "does not return other user's patterns" do
      data = fetch_mutation_with_auth(build_query, {}, user_record.id)

      patterns = data["mealFramePatterns"]
      names = patterns.map { |p| p["name"] }
      expect(names).not_to include("他ユーザーのパターン")
    end
  end
end
