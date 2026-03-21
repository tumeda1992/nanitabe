require "rails_helper"
require_relative "../../../../../../support/factories/user_repository"

RSpec.describe Business::Food::Meal::Frame::Usecase::IndexFinder do
  let(:user_record) { find_or_create_user }

  describe "#call" do
    context "when user has meal frames" do
      let!(:frame1) { MealFrame.create!(user: user_record, name: "週末枠") }
      let!(:frame2) { MealFrame.create!(user: user_record, name: "平日枠") }

      it "returns all meal frames for the user" do
        result = described_class.call(user_id: user_record.id)

        expect(result).to be_an(Array)
        expect(result.length).to eq(2)
        expect(result).to all(be_a(Business::Food::Meal::Frame::Root))

        names = result.map(&:name)
        expect(names).to include("週末枠", "平日枠")
      end
    end

    context "when user has no meal frames" do
      it "returns empty array" do
        result = described_class.call(user_id: user_record.id)

        expect(result).to eq([])
      end
    end

    context "when other user has meal frames" do
      let!(:other_user) { FactoryBot.create(:user, id_param: "other_user_param") }
      let!(:other_frame) { MealFrame.create!(user: other_user, name: "他のユーザーの枠") }

      it "does not return other user's meal frames" do
        result = described_class.call(user_id: user_record.id)

        names = result.map(&:name)
        expect(names).not_to include("他のユーザーの枠")
      end
    end
  end
end
