require "rails_helper"
require_relative "../../../../../../../support/factories/user_repository"

RSpec.describe Business::Food::Meal::Frame::Pattern::Usecase::UpdateCommand do
  let(:user_record) { find_or_create_user }
  let!(:meal_frame1) { MealFrame.create!(user: user_record, name: "朝枠") }
  let!(:meal_frame2) { MealFrame.create!(user: user_record, name: "夜枠") }
  let!(:pattern) { MealFramePattern.create!(user: user_record, name: "元のパターン名") }
  let!(:existing_entry) {
    MealFramePatternEntry.create!(
      meal_frame_pattern: pattern,
      meal_frame: meal_frame1,
      day_offset: 1,
      meal_type: 1,
    )
  }

  describe "#call" do
    context "名前変更" do
      it "パターン名が更新される" do
        described_class.call(
          meal_frame_pattern_id: pattern.id,
          name: "新しいパターン名",
          entries: [{ day_offset: 1, meal_type: 1, meal_frame_id: meal_frame1.id }],
        )

        expect(pattern.reload.name).to eq("新しいパターン名")
      end
    end

    context "エントリ全置換" do
      it "既存エントリが削除されて新しいエントリが作成される" do
        new_entries = [
          { day_offset: 2, meal_type: 3, meal_frame_id: meal_frame2.id },
          { day_offset: 3, meal_type: 1, meal_frame_id: meal_frame1.id },
        ]

        described_class.call(
          meal_frame_pattern_id: pattern.id,
          name: "更新パターン",
          entries: new_entries,
        )

        entries = MealFramePatternEntry.where(meal_frame_pattern_id: pattern.id)
        expect(entries.count).to eq(2)
        expect(entries.find_by(day_offset: 1)).to be_nil
        expect(entries.find_by(day_offset: 2)).to be_present
        expect(entries.find_by(day_offset: 3)).to be_present
      end

      it "空エントリに更新できる" do
        described_class.call(
          meal_frame_pattern_id: pattern.id,
          name: "空エントリパターン",
          entries: [],
        )

        expect(MealFramePatternEntry.where(meal_frame_pattern_id: pattern.id).count).to eq(0)
      end
    end
  end
end
