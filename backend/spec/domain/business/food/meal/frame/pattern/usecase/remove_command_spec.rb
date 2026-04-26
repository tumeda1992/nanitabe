require "rails_helper"
require_relative "../../../../../../../support/factories/user_repository"

RSpec.describe Business::Food::Meal::Frame::Pattern::Usecase::RemoveCommand do
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

  describe "#call" do
    context "削除成功" do
      it "パターンが削除される" do
        described_class.call(meal_frame_pattern_id: pattern.id)

        expect(MealFramePattern.find_by(id: pattern.id)).to be_nil
      end

      it "meal_frame_pattern_entries が cascade delete される" do
        described_class.call(meal_frame_pattern_id: pattern.id)

        expect(MealFramePatternEntry.find_by(id: entry.id)).to be_nil
      end
    end
  end
end
