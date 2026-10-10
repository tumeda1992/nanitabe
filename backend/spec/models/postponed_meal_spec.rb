require "rails_helper"
require_relative "../support/factories/user_repository"
require_relative "../support/factories/dish_repository"

RSpec.describe PostponedMeal, type: :model do
  let(:user_record) { find_or_create_user }
  let(:dish_record) { find_or_create_dish }

  describe ".build_existing_root_from_id" do
    let(:postponed_meal_record) do
      described_class.create!(user: user_record, dish: dish_record, meal_type: 3, comment: "急遽外食")
    end

    context "when postponed meal exists" do
      it "returns Business::Food::Meal::Postponed::Root with correct attributes" do
        result = described_class.build_existing_root_from_id(postponed_meal_record.id)

        expect(result).to be_a(Business::Food::Meal::Postponed::Root)
        expect(result.id).to eq(postponed_meal_record.id)
        expect(result.user_id).to eq(postponed_meal_record.user_id)
        expect(result.dish_id).to eq(postponed_meal_record.dish_id)
        expect(result.meal_type).to eq(postponed_meal_record.meal_type)
        expect(result.comment).to eq("急遽外食")
      end
    end

    context "when postponed meal does not exist" do
      it "raises ActiveRecord::RecordNotFound" do
        expect {
          described_class.build_existing_root_from_id(99_999)
        }.to raise_error(ActiveRecord::RecordNotFound, "PostponedMeal with id 99999 not found")
      end
    end
  end

  describe ".persist_from_food_meal_postponed_root" do
    let(:meal_type) { 2 }

    context "with new postponed meal (no id)" do
      let(:food_meal_postponed_root) do
        ::Business::Food::Meal::Postponed::Root.new(
          id: nil,
          user_id: user_record.id,
          dish_id: dish_record.id,
          meal_type: meal_type,
          comment: "急遽外食",
        )
      end

      it "creates new postponed_meal and calls persist_from_food_meal_postponed_root on it" do
        result = described_class.persist_from_food_meal_postponed_root(food_meal_postponed_root)

        expect(result).to be_a(PostponedMeal)
        expect(result.user_id).to eq(user_record.id)
        expect(result.dish_id).to eq(dish_record.id)
        expect(result.meal_type).to eq(meal_type)
        expect(result.comment).to eq("急遽外食")
        expect(result).to be_persisted
      end
    end

    context "with existing postponed meal (has id)" do
      let(:postponed_meal_record) do
        described_class.create!(user: user_record, dish: dish_record, meal_type: 1)
      end
      let(:new_dish_record) { FactoryBot.create(:dish) }
      let(:food_meal_postponed_root) do
        ::Business::Food::Meal::Postponed::Root.new(
          id: postponed_meal_record.id,
          user_id: user_record.id,
          dish_id: new_dish_record.id,
          meal_type: meal_type,
        )
      end

      it "finds existing postponed_meal and calls persist_from_food_meal_postponed_root on it" do
        result = described_class.persist_from_food_meal_postponed_root(food_meal_postponed_root)

        expect(result.id).to eq(postponed_meal_record.id)
        expect(result.dish_id).to eq(new_dish_record.id)
        expect(result.meal_type).to eq(meal_type)
      end
    end
  end

  describe "#persist_from_food_meal_postponed_root" do
    let(:postponed_meal_record) do
      described_class.create!(user: user_record, dish: dish_record, meal_type: 1)
    end
    let(:new_dish_record) { FactoryBot.create(:dish) }
    let(:meal_type) { 2 }

    let(:food_meal_postponed_root) do
      ::Business::Food::Meal::Postponed::Root.new(
        id: postponed_meal_record.id,
        user_id: user_record.id,
        dish_id: new_dish_record.id,
        meal_type: meal_type,
        comment: "新しいコメント",
      )
    end

    it "updates postponed_meal attributes and does not lose values on round trip" do
      result = postponed_meal_record.persist_from_food_meal_postponed_root(food_meal_postponed_root)

      expect(result.dish_id).to eq(new_dish_record.id)
      expect(result.meal_type).to eq(meal_type)
      expect(result.comment).to eq("新しいコメント")

      postponed_meal_record.reload
      expect(postponed_meal_record.dish_id).to eq(new_dish_record.id)
      expect(postponed_meal_record.meal_type).to eq(meal_type)
      expect(postponed_meal_record.comment).to eq("新しいコメント")
    end
  end
end
