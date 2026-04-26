require "rails_helper"
require_relative "../../../../../../../../support/factories/user_repository"

RSpec.describe Business::Food::Meal::Frame::Pattern::Entry::Usecase::AddCommand do
  let(:user_record) { find_or_create_user }
  let!(:meal_frame) { MealFrame.create!(user: user_record, name: "週末枠") }
  let!(:meal_frame_pattern) { MealFramePattern.create!(user: user_record, name: "テストパターン") }

  describe "#call" do
    context "with valid parameters" do
      it "creates a new pattern entry and returns Business::Food::Meal::Frame::Pattern::Entry::Root" do
        result = described_class.call(
          meal_frame_pattern_id: meal_frame_pattern.id,
          day_offset: 1,
          meal_type: 1,
          meal_frame_id: meal_frame.id,
        )

        expect(result).to be_a(Business::Food::Meal::Frame::Pattern::Entry::Root)
        expect(result.meal_frame_pattern_id).to eq(meal_frame_pattern.id)
        expect(result.day_offset).to eq(1)
        expect(result.meal_type).to eq(1)
        expect(result.meal_frame_id).to eq(meal_frame.id)
        expect(result.id).to be_present
      end

      it "creates meal frame pattern entry record in database" do
        expect {
          described_class.call(
            meal_frame_pattern_id: meal_frame_pattern.id,
            day_offset: 1,
            meal_type: 1,
            meal_frame_id: meal_frame.id,
          )
        }.to change { MealFramePatternEntry.count }.by(1)
      end
    end

    context "validations" do
      context "when day_offset is 0 or less" do
        it "raises validation error" do
          expect {
            described_class.call(
              meal_frame_pattern_id: meal_frame_pattern.id,
              day_offset: 0,
              meal_type: 1,
              meal_frame_id: meal_frame.id,
            )
          }.to raise_error(/Day offset must be greater than 0/)
        end
      end

      context "when meal_type is missing" do
        it "raises validation error" do
          expect {
            described_class.call(
              meal_frame_pattern_id: meal_frame_pattern.id,
              day_offset: 1,
              meal_type: nil,
              meal_frame_id: meal_frame.id,
            )
          }.to raise_error(/Meal type can't be blank/)
        end
      end
    end
  end
end
