require "rails_helper"
require_relative "../../../../../../support/factories/user_repository"
require_relative "../../../../../../support/factories/meal_repository"

RSpec.describe Business::Food::Meal::Frame::Entry::Usecase::UnassignMealCommand do
  let(:user_record) { find_or_create_user }
  let!(:meal_frame) { MealFrame.create!(user: user_record, name: "パスタ枠") }
  let!(:meal) { find_or_create_meal }
  let!(:meal_frame_entry) do
    MealFrameEntry.create!(
      user: user_record,
      meal_frame: meal_frame,
      date: Date.new(2026, 3, 25),
      meal_type: 2,
      meal: meal,
    )
  end

  describe "#call" do
    context "with valid parameters" do
      it "returns a FrameEntry::Root with meal_id nil" do
        result = described_class.call(
          user_id: user_record.id,
          meal_frame_entry_id: meal_frame_entry.id,
        )

        expect(result).to be_a(Business::Food::Meal::Frame::Entry::Root)
        expect(result.meal_id).to be_nil
      end

      it "persists meal_id as nil to the meal_frame_entries record" do
        described_class.call(
          user_id: user_record.id,
          meal_frame_entry_id: meal_frame_entry.id,
        )

        updated_record = MealFrameEntry.find(meal_frame_entry.id)
        expect(updated_record.meal_id).to be_nil
      end
    end

    context "with invalid parameters" do
      it "raises ActiveRecord::RecordNotFound when meal_frame_entry_id does not exist" do
        expect do
          described_class.call(
            user_id: user_record.id,
            meal_frame_entry_id: 0,
          )
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
