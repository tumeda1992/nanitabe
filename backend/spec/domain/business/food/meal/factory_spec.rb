require "rails_helper"
require_relative "../../../../support/factories/user_repository"
require_relative "../../../../support/factories/dish_repository"

RSpec.describe Business::Food::Meal::Factory do
  let(:user_record) { find_or_create_user }
  let(:dish_record) { find_or_create_dish }

  describe ".build" do
    let(:date) { Date.today }
    let(:meal_type) { 1 }
    let(:comment) { "test comment" }

    context "with valid parameters" do
      it "returns Business::Food::Meal::Root with correct attributes" do
        result = described_class.build(
          user_record.id,
          dish_record.id,
          date,
          meal_type,
          comment: comment,
        )

        expect(result).to be_a(Business::Food::Meal::Root)
        expect(result.user_id).to eq(user_record.id)
        expect(result.dish_id).to eq(dish_record.id)
        expect(result.date).to eq(date)
        expect(result.meal_type).to eq(meal_type)
        expect(result.comment).to eq(comment)
      end
    end

    context "without comment" do
      it "returns Business::Food::Meal::Root with nil comment" do
        result = described_class.build(
          user_record.id,
          dish_record.id,
          date,
          meal_type,
        )

        expect(result).to be_a(Business::Food::Meal::Root)
        expect(result.comment).to be_nil
      end
    end

    context "with invalid dish_id" do
      it "raises error" do
        expect {
          described_class.build(
            user_record.id,
            999999,
            date,
            meal_type,
          )
        }.to raise_error("存在しない料理を紐付けることはできません。")
      end
    end

    context "with blank dish_id" do
      it "raises error" do
        expect {
          described_class.build(
            user_record.id,
            nil,
            date,
            meal_type,
          )
        }.to raise_error("料理が指定されていません。")
      end
    end
  end

  describe ".build_existing_from_id" do
    let(:meal_record) { FactoryBot.create(:meal, user: user_record, dish: dish_record) }

    it "calls Meal.build_existing_root_from_id" do
      expect(::Meal).to receive(:build_existing_root_from_id)
        .with(meal_record.id)
        .and_call_original

      described_class.build_existing_from_id(meal_record.id)
    end
  end
end
