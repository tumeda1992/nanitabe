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
        comment: "test meal",
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
          described_class.build_existing_root_from_id(99_999)
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

  describe ".persist_from_food_meal_root" do
    let(:meal_name) { "test meal" }
    let(:meal_date) { Date.today }
    let(:meal_type) { 2 }
    let(:comment) { "test comment" }

    context "with new meal (no id)" do
      let(:food_meal_root) do
        ::Business::Food::Meal::Root.new(
          id: nil,
          user_id: user_record.id,
          dish_id: dish_record.id,
          date: meal_date,
          meal_type: meal_type,
          comment: comment,
        )
      end

      it "creates new meal and calls persist_from_food_meal_root on it" do
        result = described_class.persist_from_food_meal_root(food_meal_root)

        expect(result).to be_a(Meal)
        expect(result.user_id).to eq(user_record.id)
        expect(result.dish_id).to eq(dish_record.id)
        expect(result.date).to eq(meal_date)
        expect(result.meal_type).to eq(meal_type)
        expect(result.comment).to eq(comment)
        expect(result).to be_persisted
      end
    end

    context "with existing meal (has id)" do
      let(:meal_record) do
        FactoryBot.create(
          :meal,
          user: user_record,
          dish: dish_record,
          date: Date.yesterday,
          meal_type: 1,
          comment: "old comment",
        )
      end
      let(:food_meal_root) do
        ::Business::Food::Meal::Root.new(
          id: meal_record.id,
          user_id: user_record.id,
          dish_id: dish_record.id,
          date: meal_date,
          meal_type: meal_type,
          comment: comment,
        )
      end

      it "finds existing meal and calls persist_from_food_meal_root on it" do
        result = described_class.persist_from_food_meal_root(food_meal_root)

        expect(result.id).to eq(meal_record.id)
        expect(result.dish_id).to eq(dish_record.id)
        expect(result.date).to eq(meal_date)
        expect(result.meal_type).to eq(meal_type)
        expect(result.comment).to eq(comment)
      end
    end
  end

  describe "#persist_from_food_meal_root" do
    let(:meal_record) do
      FactoryBot.create(
        :meal,
        user: user_record,
        dish: dish_record,
        date: Date.yesterday,
        meal_type: 1,
        comment: "old comment",
      )
    end
    let(:new_dish_record) { FactoryBot.create(:dish, user: user_record) }
    let(:meal_date) { Date.today }
    let(:meal_type) { 2 }
    let(:comment) { "new comment" }

    let(:food_meal_root) do
      ::Business::Food::Meal::Root.new(
        id: meal_record.id,
        user_id: user_record.id,
        dish_id: new_dish_record.id,
        date: meal_date,
        meal_type: meal_type,
        comment: comment,
      )
    end

    it "updates meal attributes" do
      result = meal_record.persist_from_food_meal_root(food_meal_root)

      expect(result.dish_id).to eq(new_dish_record.id)
      expect(result.date).to eq(meal_date)
      expect(result.meal_type).to eq(meal_type)
      expect(result.comment).to eq(comment)

      meal_record.reload
      expect(meal_record.dish_id).to eq(new_dish_record.id)
      expect(meal_record.date).to eq(meal_date)
      expect(meal_record.meal_type).to eq(meal_type)
      expect(meal_record.comment).to eq(comment)
    end
  end
end
