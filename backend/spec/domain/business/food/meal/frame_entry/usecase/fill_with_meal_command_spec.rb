require "rails_helper"
require_relative "../../../../../../support/factories/user_repository"
require_relative "../../../../../../support/factories/meal_repository"

RSpec.describe Business::Food::Meal::FrameEntry::Usecase::FillWithMealCommand do
  let(:user_record) { find_or_create_user }
  let!(:meal_frame) { MealFrame.create!(user: user_record, name: "パスタ枠") }
  let!(:meal_frame_entry) do
    MealFrameEntry.create!(
      user: user_record,
      meal_frame: meal_frame,
      date: Date.new(2026, 3, 25),
      meal_type: 2,
    )
  end
  let!(:meal) { find_or_create_meal }

  describe "#call" do
    context "with valid parameters" do
      it "returns a FrameEntry::Root with meal_id set" do
        result = described_class.call(
          user_id: user_record.id,
          meal_frame_entry_id: meal_frame_entry.id,
          meal_id: meal.id,
        )

        expect(result).to be_a(Business::Food::Meal::Frame::Entry::Root)
        expect(result.meal_id).to eq(meal.id)
      end

      it "persists meal_id to the meal_frame_entries record" do
        described_class.call(
          user_id: user_record.id,
          meal_frame_entry_id: meal_frame_entry.id,
          meal_id: meal.id,
        )

        updated_record = MealFrameEntry.find(meal_frame_entry.id)
        expect(updated_record.meal_id).to eq(meal.id)
      end
    end
  end
end
