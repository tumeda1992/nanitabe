require "rails_helper"
require_relative "../../../../../support/factories/user_repository"
require_relative "../../../../../support/factories/dish_repository"

RSpec.describe Business::Food::Meal::Usecase::AddCommand do
  let(:user_record) { find_or_create_user }
  let(:dish_record) { find_or_create_dish }

  let(:valid_meal_params) do
    Business::Food::Meal::Usecase::Params::Meal.new(
      :create,
      dish_id: dish_record.id,
      date: Date.today,
      meal_type: 1,
      comment: "test meal",
    )
  end

  describe "#call" do
    context "with valid parameters" do
      it "creates a new meal and returns Business::Food::Meal::Root" do
        result = described_class.call(
          user_id: user_record.id,
          meal_params: valid_meal_params,
        )

        expect(result).to be_a(Business::Food::Meal::Root)
        expect(result.user_id).to eq(user_record.id)
        expect(result.dish_id).to eq(dish_record.id)
        expect(result.date).to eq(Date.today)
        expect(result.meal_type).to eq(1)
        expect(result.comment).to eq("test meal")
        expect(result.id).to be_present
      end

      it "creates meal record in database" do
        expect {
          described_class.call(
            user_id: user_record.id,
            meal_params: valid_meal_params,
          )
        }.to change { Meal.count }.by(1)

        created_meal = Meal.last
        expect(created_meal.user_id).to eq(user_record.id)
        expect(created_meal.dish_id).to eq(dish_record.id)
        expect(created_meal.date).to eq(Date.today)
        expect(created_meal.meal_type).to eq(1)
        expect(created_meal.comment).to eq("test meal")
      end
    end

    context "with blank comment" do
      let(:meal_params_without_comment) do
        Business::Food::Meal::Usecase::Params::Meal.new(
          :create,
          dish_id: dish_record.id,
          date: Date.today,
          meal_type: 1,
        )
      end

      it "creates meal without comment" do
        result = described_class.call(
          user_id: user_record.id,
          meal_params: meal_params_without_comment,
        )

        expect(result.comment).to be_nil
      end
    end
  end

  describe "validations" do
    context "when user_id is missing" do
      it "raises validation error" do
        expect {
          described_class.call(
            meal_params: valid_meal_params,
          )
        }.to raise_error(/User can't be blank/)
      end
    end

    context "when meal_params is missing" do
      it "raises validation error" do
        expect {
          described_class.call(
            user_id: user_record.id,
          )
        }.to raise_error(/Meal params can't be blank/)
      end
    end

    context "when user_id is nil" do
      it "raises validation error" do
        expect {
          described_class.call(
            user_id: nil,
            meal_params: valid_meal_params,
          )
        }.to raise_error(/User can't be blank/)
      end
    end

    context "when meal_params is nil" do
      it "raises validation error" do
        expect {
          described_class.call(
            user_id: user_record.id,
            meal_params: nil,
          )
        }.to raise_error(/Meal params can't be blank/)
      end
    end

    context "with invalid dish_id in meal_params" do
      let(:invalid_meal_params) do
        Business::Food::Meal::Usecase::Params::Meal.new(
          :create,
          dish_id: 999_999,
          date: Date.today,
          meal_type: 1,
          comment: "test meal",
        )
      end

      it "raises validation error" do
        expect {
          described_class.call(
            user_id: user_record.id,
            meal_params: invalid_meal_params,
          )
        }.to raise_error("存在しない料理を紐付けることはできません。")
      end
    end
  end
end
