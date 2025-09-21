require "rails_helper"
require_relative "../support/factories/user_repository"
require_relative "../support/factories/dish_repository"

RSpec.describe Meal, type: :model do
  let(:user_record) { find_or_create_user }
  let(:dish_record) { find_or_create_dish }

  describe ".build_existing_root_from_id" do
    let(:meal_record) do
      FactoryBot.create(
        :meal,
        user: user_record,
        dish: dish_record,
        date: Date.today,
        meal_type: 1,
        comment: "test meal"
      )
    end

    context "when meal exists" do
      it "returns Business::Food::Meal::Root with correct attributes" do
        result = described_class.build_existing_root_from_id(meal_record.id)

        expect(result).to be_a(Business::Food::Meal::Root)
        expect(result.id).to eq(meal_record.id)
        expect(result.user_id).to eq(meal_record.user_id)
        expect(result.dish_id).to eq(meal_record.dish_id)
        expect(result.date).to eq(meal_record.date)
        expect(result.meal_type).to eq(meal_record.meal_type)
        expect(result.comment).to eq(meal_record.comment)
      end
    end

    context "when meal does not exist" do
      it "raises ActiveRecord::RecordNotFound" do
        expect {
          described_class.build_existing_root_from_id(99999)
        }.to raise_error(ActiveRecord::RecordNotFound, "Meal with id 99999 not found")
      end
    end

    context "when id is nil" do
      it "raises ActiveRecord::RecordNotFound" do
        expect {
          described_class.build_existing_root_from_id(nil)
        }.to raise_error(ActiveRecord::RecordNotFound, "Meal with id  not found")
      end
    end
  end
end