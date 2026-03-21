require "rails_helper"
require_relative "../../../../../../support/factories/user_repository"

RSpec.describe Business::Food::Meal::FrameEntry::Usecase::AddCommand do
  let(:user_record) { find_or_create_user }
  let!(:meal_frame) { MealFrame.create!(user: user_record, name: "週末枠") }

  describe "#call" do
    context "with valid parameters" do
      it "creates a new meal frame entry and returns Business::Food::Meal::FrameEntry::Root" do
        result = described_class.call(
          user_id: user_record.id,
          meal_frame_id: meal_frame.id,
          date: Date.today,
          meal_type: 1,
        )

        expect(result).to be_a(Business::Food::Meal::FrameEntry::Root)
        expect(result.user_id).to eq(user_record.id)
        expect(result.meal_frame_id).to eq(meal_frame.id)
        expect(result.date).to eq(Date.today)
        expect(result.meal_type).to eq(1)
        expect(result.id).to be_present
      end

      it "creates meal frame entry record in database" do
        expect {
          described_class.call(
            user_id: user_record.id,
            meal_frame_id: meal_frame.id,
            date: Date.today,
            meal_type: 1,
          )
        }.to change { MealFrameEntry.count }.by(1)
      end
    end

    context "validations" do
      context "when user_id is missing" do
        it "raises validation error" do
          expect {
            described_class.call(
              meal_frame_id: meal_frame.id,
              date: Date.today,
              meal_type: 1,
            )
          }.to raise_error(/User can't be blank/)
        end
      end

      context "when meal_frame_id is missing" do
        it "raises validation error" do
          expect {
            described_class.call(
              user_id: user_record.id,
              date: Date.today,
              meal_type: 1,
            )
          }.to raise_error(/Meal frame can't be blank/)
        end
      end
    end
  end
end
