require "rails_helper"
require_relative "../../../../../support/factories/user_repository"
require_relative "../../../../../support/factories/dish_repository"

RSpec.describe Business::Food::Meal::Policy::AttachDishPolicy do
  let(:user_record) { find_or_create_user }
  let(:dish_record) { find_or_create_dish }

  describe ".ensure!" do
    context "with valid dish_id" do
      it "returns true" do
        result = described_class.ensure!(dish_record.id)
        expect(result).to be true
      end
    end

    context "with blank dish_id" do
      it "raises error" do
        expect {
          described_class.ensure!(nil)
        }.to raise_error("料理が指定されていません。")
      end

      it "raises error with empty string" do
        expect {
          described_class.ensure!("")
        }.to raise_error("料理が指定されていません。")
      end
    end

    context "with non-existing dish_id" do
      it "raises error" do
        expect {
          described_class.ensure!(999999)
        }.to raise_error("存在しない料理を紐付けることはできません。")
      end
    end
  end
end