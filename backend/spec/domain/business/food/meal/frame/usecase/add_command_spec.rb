require "rails_helper"
require_relative "../../../../../../support/factories/user_repository"

RSpec.describe Business::Food::Meal::Frame::Usecase::AddCommand do
  let(:user_record) { find_or_create_user }

  describe "#call" do
    context "with valid parameters" do
      it "creates a new meal frame and returns Business::Food::Meal::Frame::Root" do
        result = described_class.call(
          user_id: user_record.id,
          name: "週末枠",
        )

        expect(result).to be_a(Business::Food::Meal::Frame::Root)
        expect(result.user_id).to eq(user_record.id)
        expect(result.name).to eq("週末枠")
        expect(result.id).to be_present
      end

      it "creates meal frame record in database" do
        expect {
          described_class.call(
            user_id: user_record.id,
            name: "週末枠",
          )
        }.to change { MealFrame.count }.by(1)

        created_frame = MealFrame.last
        expect(created_frame.user_id).to eq(user_record.id)
        expect(created_frame.name).to eq("週末枠")
      end
    end

    context "validations" do
      context "when user_id is missing" do
        it "raises validation error" do
          expect {
            described_class.call(
              name: "週末枠",
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
            )
          }.to raise_error(/Name can't be blank/)
        end
      end

      context "when name is empty string" do
        it "raises validation error" do
          expect {
            described_class.call(
              user_id: user_record.id,
              name: "",
            )
          }.to raise_error(/Name can't be blank/)
        end
      end
    end
  end
end
