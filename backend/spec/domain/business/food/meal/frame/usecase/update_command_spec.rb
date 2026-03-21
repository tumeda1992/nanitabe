require "rails_helper"
require_relative "../../../../../../support/factories/user_repository"

RSpec.describe Business::Food::Meal::Frame::Usecase::UpdateCommand do
  let(:user_record) { find_or_create_user }
  let!(:meal_frame) { MealFrame.create!(user: user_record, name: "元の枠名") }

  describe "#call" do
    context "with valid parameters" do
      it "renames the meal frame and returns Business::Food::Meal::Frame::Root" do
        result = described_class.call(
          user_id: user_record.id,
          meal_frame_id: meal_frame.id,
          name: "新しい枠名",
        )

        expect(result).to be_a(Business::Food::Meal::Frame::Root)
        expect(result.name).to eq("新しい枠名")
        expect(result.id).to eq(meal_frame.id)
      end

      it "updates meal frame record in database" do
        described_class.call(
          user_id: user_record.id,
          meal_frame_id: meal_frame.id,
          name: "新しい枠名",
        )

        expect(meal_frame.reload.name).to eq("新しい枠名")
      end
    end

    context "validations" do
      context "when name is blank" do
        it "raises validation error" do
          expect {
            described_class.call(
              user_id: user_record.id,
              meal_frame_id: meal_frame.id,
              name: "",
            )
          }.to raise_error(/Name can't be blank/)
        end
      end

      context "when meal_frame_id is missing" do
        it "raises validation error" do
          expect {
            described_class.call(
              user_id: user_record.id,
              name: "新しい枠名",
            )
          }.to raise_error(/Meal frame can't be blank/)
        end
      end
    end
  end
end
