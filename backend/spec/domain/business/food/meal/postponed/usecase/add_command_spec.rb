require "rails_helper"
require_relative "../../../../../../support/factories/user_repository"
require_relative "../../../../../../support/factories/dish_repository"

RSpec.describe Business::Food::Meal::Postponed::Usecase::AddCommand do
  let(:user_record) { find_or_create_user }
  let(:dish_record) { find_or_create_dish }

  describe "#call" do
    context "with valid parameters" do
      it "creates a new postponed meal and returns Business::Food::Meal::Postponed::Root" do
        result = described_class.call(
          user_id: user_record.id,
          dish_id: dish_record.id,
          meal_type: 3,
          comment: "急遽外食",
        )

        expect(result).to be_a(Business::Food::Meal::Postponed::Root)
        expect(result.user_id).to eq(user_record.id)
        expect(result.dish_id).to eq(dish_record.id)
        expect(result.meal_type).to eq(3)
        expect(result.comment).to eq("急遽外食")
        expect(result.id).to be_present
      end

      it "creates a postponed meal with a NULL comment when comment is not given" do
        result = described_class.call(
          user_id: user_record.id,
          dish_id: dish_record.id,
          meal_type: 3,
        )

        expect(result.comment).to be_nil
        expect(PostponedMeal.find(result.id).comment).to be_nil
      end

      it "creates postponed_meal record in database" do
        expect {
          described_class.call(
            user_id: user_record.id,
            dish_id: dish_record.id,
            meal_type: 3,
          )
        }.to change { PostponedMeal.count }.by(1)
      end

      it "allows creating a second postponed meal for the same dish and meal_type" do
        described_class.call(user_id: user_record.id, dish_id: dish_record.id, meal_type: 3)

        expect {
          described_class.call(user_id: user_record.id, dish_id: dish_record.id, meal_type: 3)
        }.to change { PostponedMeal.count }.by(1)
      end
    end

    context "validations" do
      context "when user_id is missing" do
        it "raises validation error" do
          expect {
            described_class.call(dish_id: dish_record.id, meal_type: 3)
          }.to raise_error(/User can't be blank/)
        end
      end

      context "when dish_id is missing" do
        it "raises validation error" do
          expect {
            described_class.call(user_id: user_record.id, meal_type: 3)
          }.to raise_error(/Dish can't be blank/)
        end
      end

      context "when meal_type is missing" do
        it "raises validation error" do
          expect {
            described_class.call(user_id: user_record.id, dish_id: dish_record.id)
          }.to raise_error(/Meal type can't be blank/)
        end
      end
    end
  end
end
