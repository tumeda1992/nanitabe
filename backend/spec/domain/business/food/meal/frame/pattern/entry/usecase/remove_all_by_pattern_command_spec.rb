require "rails_helper"
require_relative "../../../../../../../../support/factories/user_repository"

RSpec.describe Business::Food::Meal::Frame::Pattern::Entry::Usecase::RemoveAllByPatternCommand do
  let(:user_record) { find_or_create_user }
  let!(:meal_frame) { MealFrame.create!(user: user_record, name: "週末枠") }
  let!(:pattern) { MealFramePattern.create!(user: user_record, name: "テストパターン") }
  let!(:entry1) {
    MealFramePatternEntry.create!(
      meal_frame_pattern: pattern,
      meal_frame: meal_frame,
      day_offset: 1,
      meal_type: 1,
    )
  }
  let!(:entry2) {
    MealFramePatternEntry.create!(
      meal_frame_pattern: pattern,
      meal_frame: meal_frame,
      day_offset: 2,
      meal_type: 3,
    )
  }

  describe "#call" do
    context "with valid pattern_id" do
      it "deletes all entries for the given pattern" do
        expect {
          described_class.call(meal_frame_pattern_id: pattern.id)
        }.to change { MealFramePatternEntry.where(meal_frame_pattern_id: pattern.id).count }.from(2).to(0)
      end

      it "does not delete entries from other patterns" do
        other_pattern = MealFramePattern.create!(user: user_record, name: "別パターン")
        other_entry = MealFramePatternEntry.create!(
          meal_frame_pattern: other_pattern,
          meal_frame: meal_frame,
          day_offset: 1,
          meal_type: 1,
        )

        described_class.call(meal_frame_pattern_id: pattern.id)

        expect(MealFramePatternEntry.find_by(id: other_entry.id)).to be_present
      end
    end
  end
end
