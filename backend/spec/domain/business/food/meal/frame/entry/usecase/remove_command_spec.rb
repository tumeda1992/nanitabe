require "rails_helper"
require_relative "../../../../../../../support/factories/user_repository"

RSpec.describe Business::Food::Meal::Frame::Entry::Usecase::RemoveCommand do
  let(:user_record) { find_or_create_user }
  let!(:meal_frame) { MealFrame.create!(user: user_record, name: "テスト枠") }
  let!(:meal_frame_entry) do
    MealFrameEntry.create!(
      user: user_record,
      meal_frame: meal_frame,
      date: Date.today,
      meal_type: 3,
    )
  end

  describe "#call" do
    context "with valid parameters" do
      it "removes the meal frame entry from database" do
        expect {
          described_class.call(
            user_id: user_record.id,
            meal_frame_entry_id: meal_frame_entry.id,
          )
        }.to change { MealFrameEntry.count }.by(-1)

        expect(MealFrameEntry.find_by(id: meal_frame_entry.id)).to be_nil
      end

      it "returns the removed meal_frame_entry_id" do
        result = described_class.call(
          user_id: user_record.id,
          meal_frame_entry_id: meal_frame_entry.id,
        )

        expect(result).to eq(meal_frame_entry.id)
      end
    end

    context "validations" do
      context "when meal_frame_entry_id is missing" do
        it "raises validation error" do
          expect {
            described_class.call(
              user_id: user_record.id,
            )
          }.to raise_error(/Meal frame entry can't be blank/)
        end
      end
    end
  end
end
