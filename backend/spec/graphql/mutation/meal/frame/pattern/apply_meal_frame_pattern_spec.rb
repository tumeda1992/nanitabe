require "rails_helper"
require_relative "../../../../graphql_auth_helper"
require_relative "../../../../../support/factories/user_repository"

module Mutations::Meal::Frame::Pattern
  RSpec.describe ApplyMealFramePattern, type: :request do
    let(:user_record) { find_or_create_user }
    let!(:meal_frame1) { MealFrame.create!(user: user_record, name: "朝枠") }
    let!(:meal_frame2) { MealFrame.create!(user: user_record, name: "夜枠") }
    let!(:pattern) { MealFramePattern.create!(user: user_record, name: "糖質オフ週") }
    let!(:entry_day1_morning) do
      MealFramePatternEntry.create!(
        meal_frame_pattern: pattern,
        meal_frame: meal_frame1,
        day_offset: 1,
        meal_type: 1,
      )
    end
    let!(:entry_day1_evening) do
      MealFramePatternEntry.create!(
        meal_frame_pattern: pattern,
        meal_frame: meal_frame2,
        day_offset: 1,
        meal_type: 3,
      )
    end
    let!(:entry_day3) do
      MealFramePatternEntry.create!(
        meal_frame_pattern: pattern,
        meal_frame: meal_frame1,
        day_offset: 3,
        meal_type: 3,
      )
    end

    def build_mutation
      <<~GRAPHQL
        mutation applyMealFramePattern($patternId: Int!, $startDate: String!) {
          applyMealFramePattern(input: { patternId: $patternId, startDate: $startDate }) {
            appliedMealFramePatternId
          }
        }
      GRAPHQL
    end

    context "正常ケース: 空の日を含むパターンで正しい日付に MealFrameEntry が作成される" do
      it "パターンのエントリ数分だけ MealFrameEntry が作成され、appliedMealFramePatternId が返る" do
        start_date = "2026-04-28"
        variables = { patternId: pattern.id, startDate: start_date }

        expect {
          result = fetch_mutation_with_auth(build_mutation, variables, user_record.id)
          expect(result["applyMealFramePattern"]["appliedMealFramePatternId"]).to eq(pattern.id)
        }.to change { MealFrameEntry.count }.by(3)
      end

      it "day_offset に基づいた正しい日付で MealFrameEntry が作成される" do
        start_date = "2026-04-28"
        variables = { patternId: pattern.id, startDate: start_date }
        fetch_mutation_with_auth(build_mutation, variables, user_record.id)

        entries = MealFrameEntry.where(user: user_record).order(:date, :meal_type)

        # day_offset=1 の2件 → 2026-04-28
        april_28_entries = entries.select { |e| e.date == Date.parse("2026-04-28") }
        expect(april_28_entries.length).to eq(2)
        expect(april_28_entries.map(&:meal_type).sort).to eq([1, 3])
        expect(april_28_entries.map(&:meal_frame_id).sort).to eq([meal_frame1.id, meal_frame2.id].sort)

        # day_offset=2 はエントリなし → 2026-04-29 は何も生成されない
        april_29_entries = entries.select { |e| e.date == Date.parse("2026-04-29") }
        expect(april_29_entries.length).to eq(0)

        # day_offset=3 の1件 → 2026-04-30
        april_30_entries = entries.select { |e| e.date == Date.parse("2026-04-30") }
        expect(april_30_entries.length).to eq(1)
        expect(april_30_entries.first.meal_type).to eq(3)
        expect(april_30_entries.first.meal_frame_id).to eq(meal_frame1.id)
      end
    end

    context "パターン所有者チェック: 他ユーザーのパターンは適用不可" do
      let!(:other_user_record) { User.create!(id_param: "other_user_for_apply_test") }
      let!(:other_pattern) { MealFramePattern.create!(user: other_user_record, name: "他ユーザーのパターン") }

      it "他ユーザーのパターンを適用しようとするとエラーが発生する" do
        variables = { patternId: other_pattern.id, startDate: "2026-04-28" }

        expect {
          fetch_mutation_with_auth(build_mutation, variables, user_record.id)
        }.to raise_error(/パターンが見つからないか、アクセス権がありません/)
      end
    end
  end
end
