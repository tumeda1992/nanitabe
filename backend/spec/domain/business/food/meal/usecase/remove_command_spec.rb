require "rails_helper"
require_relative "../../../../../support/factories/user_repository"
require_relative "../../../../../support/factories/dish_repository"

RSpec.describe Business::Food::Meal::Usecase::RemoveCommand do
  let(:user_record) { find_or_create_user }
  let(:dish_record) { find_or_create_dish }
  let(:existing_meal_record) do
    FactoryBot.create(
      :meal,
      user: user_record,
      dish: dish_record,
      date: Date.today,
      meal_type: 1,
      comment: "test meal",
    )
  end

  describe "#call" do
    context "with valid parameters" do
      it "removes the meal from database" do
        meal_id = existing_meal_record.id

        expect {
          described_class.call(
            user_id: user_record.id,
            meal_id: meal_id,
          )
        }.to change { Meal.count }.by(-1)

        expect(Meal.find_by(id: meal_id)).to be_nil
      end

      it "returns the destroyed meal object when meal is successfully removed" do
        result = described_class.call(
          user_id: user_record.id,
          meal_id: existing_meal_record.id,
        )

        expect(result).to be_a(Meal)
        expect(result.destroyed?).to be true
        expect(result.id).to eq(existing_meal_record.id)
      end
    end

    context "when meal does not exist" do
      it "raises error" do
        expect {
          described_class.call(
            user_id: user_record.id,
            meal_id: 99999,
          )
        }.to raise_error("指定した食事は存在しません。")
      end

      it "does not change meal count" do
        expect {
          begin
            described_class.call(
              user_id: user_record.id,
              meal_id: 99999,
            )
          rescue => e
            # Ignore the exception for count check
          end
        }.not_to change { Meal.count }
      end
    end

  end

  describe "validations" do
    context "when user_id is missing" do
      it "raises validation error" do
        expect {
          described_class.call(meal_id: existing_meal_record.id)
        }.to raise_error(/User can't be blank/)
      end
    end

    context "when meal_id is missing" do
      it "raises validation error" do
        expect {
          described_class.call(user_id: user_record.id)
        }.to raise_error(/Meal can't be blank/)
      end
    end

    context "when user_id is nil" do
      it "raises validation error" do
        expect {
          described_class.call(
            user_id: nil,
            meal_id: existing_meal_record.id,
          )
        }.to raise_error(/User can't be blank/)
      end
    end

    context "when meal_id is explicitly nil" do
      it "raises validation error" do
        expect {
          described_class.call(
            user_id: user_record.id,
            meal_id: nil,
          )
        }.to raise_error(/Meal can't be blank/)
      end
    end
  end
end
