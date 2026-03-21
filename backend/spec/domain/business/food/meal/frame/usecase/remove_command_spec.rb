require "rails_helper"
require_relative "../../../../../../support/factories/user_repository"

RSpec.describe Business::Food::Meal::Frame::Usecase::RemoveCommand do
  let(:user_record) { find_or_create_user }
  let!(:meal_frame) { MealFrame.create!(user: user_record, name: "削除対象の枠") }

  describe "#call" do
    context "with valid parameters (no entries)" do
      it "removes the meal frame from database" do
        expect {
          described_class.call(
            user_id: user_record.id,
            meal_frame_id: meal_frame.id,
          )
        }.to change { MealFrame.count }.by(-1)

        expect(MealFrame.find_by(id: meal_frame.id)).to be_nil
      end

      it "returns the removed meal_frame_id" do
        result = described_class.call(
          user_id: user_record.id,
          meal_frame_id: meal_frame.id,
        )

        expect(result).to eq(meal_frame.id)
      end
    end

    context "when meal frame has entries" do
      let!(:meal_frame_entry) do
        MealFrameEntry.create!(
          user: user_record,
          meal_frame: meal_frame,
          date: Date.today,
          meal_type: 1,
        )
      end

      it "raises error and does not delete meal frame" do
        expect {
          described_class.call(
            user_id: user_record.id,
            meal_frame_id: meal_frame.id,
          )
        }.to raise_error(/枠にエントリが登録されているため削除できません/)

        expect(MealFrame.find_by(id: meal_frame.id)).to be_present
      end
    end

    context "validations" do
      context "when meal_frame_id is missing" do
        it "raises validation error" do
          expect {
            described_class.call(
              user_id: user_record.id,
            )
          }.to raise_error(/Meal frame can't be blank/)
        end
      end
    end
  end
end
