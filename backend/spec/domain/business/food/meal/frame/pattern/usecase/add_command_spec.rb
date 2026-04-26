require "rails_helper"
require_relative "../../../../../../../support/factories/user_repository"

RSpec.describe Business::Food::Meal::Frame::Pattern::Usecase::AddCommand do
  let(:user_record) { find_or_create_user }
  let!(:meal_frame1) { MealFrame.create!(user: user_record, name: "朝枠") }
  let!(:meal_frame2) { MealFrame.create!(user: user_record, name: "夜枠") }

  describe "#call" do
    context "with valid parameters (no entries)" do
      it "creates a new pattern without entries and returns Business::Food::Meal::Frame::Pattern::Root" do
        result = described_class.call(
          user_id: user_record.id,
          name: "テストパターン",
          entries: [],
        )

        expect(result).to be_a(Business::Food::Meal::Frame::Pattern::Root)
        expect(result.user_id).to eq(user_record.id)
        expect(result.name).to eq("テストパターン")
        expect(result.id).to be_present
      end

      it "creates meal frame pattern record in database" do
        expect {
          described_class.call(
            user_id: user_record.id,
            name: "テストパターン",
            entries: [],
          )
        }.to change { MealFramePattern.count }.by(1)
      end
    end

    context "with entries" do
      it "creates pattern with entries in single transaction" do
        entries = [
          { day_offset: 1, meal_type: 1, meal_frame_id: meal_frame1.id },
          { day_offset: 1, meal_type: 3, meal_frame_id: meal_frame2.id },
          { day_offset: 2, meal_type: 3, meal_frame_id: meal_frame1.id },
        ]

        result = described_class.call(
          user_id: user_record.id,
          name: "糖質オフ週",
          entries:,
        )

        expect(result).to be_a(Business::Food::Meal::Frame::Pattern::Root)
        expect(result.id).to be_present

        pattern = MealFramePattern.find(result.id)
        expect(pattern.meal_frame_pattern_entries.count).to eq(3)
      end

      it "allows multiple entries with same day_offset and different meal_type" do
        entries = [
          { day_offset: 1, meal_type: 1, meal_frame_id: meal_frame1.id },
          { day_offset: 1, meal_type: 3, meal_frame_id: meal_frame2.id },
        ]

        expect {
          described_class.call(
            user_id: user_record.id,
            name: "同日複数枠パターン",
            entries:,
          )
        }.to change { MealFramePatternEntry.count }.by(2)
      end
    end

    context "validations" do
      context "when user_id is missing" do
        it "raises validation error" do
          expect {
            described_class.call(
              name: "テストパターン",
              entries: [],
            )
          }.to raise_error(/User can't be blank/)
        end
      end

      context "when name is missing" do
        it "raises validation error" do
          expect {
            described_class.call(
              user_id: user_record.id,
              name: nil,
              entries: [],
            )
          }.to raise_error(/Name can't be blank/)
        end
      end
    end
  end
end
