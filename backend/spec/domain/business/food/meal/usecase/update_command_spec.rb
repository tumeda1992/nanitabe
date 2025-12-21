require "rails_helper"
require_relative "../../../../../support/factories/user_repository"
require_relative "../../../../../support/factories/dish_repository"

RSpec.describe Business::Food::Meal::Usecase::UpdateCommand do
  let(:user_record) { find_or_create_user }
  let(:dish_record) { find_or_create_dish }
  let(:existing_meal_record) do
    FactoryBot.create(
      :meal,
      user: user_record,
      dish: dish_record,
      date: Date.yesterday,
      meal_type: 1,
      comment: "old comment",
    )
  end

  let(:valid_meal_params) do
    Business::Food::Meal::Usecase::Params::Meal.new(
      :update,
      id: existing_meal_record.id,
      dish_id: dish_record.id,
      date: Date.today,
      meal_type: 2,
      comment: "updated comment",
    )
  end

  describe "#call" do
    context "with valid parameters" do
      it "updates meal and returns Business::Food::Meal::Root" do
        result = described_class.call(
          user_id: user_record.id,
          meal_params: valid_meal_params,
        )

        expect(result).to be_a(Business::Food::Meal::Root)
        expect(result.id).to eq(existing_meal_record.id)
        expect(result.user_id).to eq(user_record.id)
        expect(result.dish_id).to eq(dish_record.id)
        expect(result.date).to eq(Date.today)
        expect(result.meal_type).to eq(2)
        expect(result.comment).to eq("updated comment")
      end

      it "updates meal in database" do
        described_class.call(
          user_id: user_record.id,
          meal_params: valid_meal_params,
        )

        updated_meal = ::Meal.find(existing_meal_record.id)
        expect(updated_meal.dish_id).to eq(dish_record.id)
        expect(updated_meal.date).to eq(Date.today)
        expect(updated_meal.meal_type).to eq(2)
        expect(updated_meal.comment).to eq("updated comment")
      end

      context "when updating only date" do
        let(:date_only_params) do
          Business::Food::Meal::Usecase::Params::Meal.new(
            :update,
            id: existing_meal_record.id,
            dish_id: existing_meal_record.dish_id,
            date: Date.today,
            meal_type: existing_meal_record.meal_type,
          )
        end

        it "updates only date" do
          result = described_class.call(
            user_id: user_record.id,
            meal_params: date_only_params,
          )

          expect(result.dish_id).to eq(existing_meal_record.dish_id)
          expect(result.date).to eq(Date.today)
          expect(result.meal_type).to eq(existing_meal_record.meal_type)
          expect(result.comment).to eq(existing_meal_record.comment)
        end
      end

      context "when updating only meal_type" do
        let(:meal_type_only_params) do
          Business::Food::Meal::Usecase::Params::Meal.new(
            :update,
            id: existing_meal_record.id,
            dish_id: existing_meal_record.dish_id,
            date: existing_meal_record.date,
            meal_type: 3,
          )
        end

        it "updates only meal_type" do
          result = described_class.call(
            user_id: user_record.id,
            meal_params: meal_type_only_params,
          )

          expect(result.dish_id).to eq(existing_meal_record.dish_id)
          expect(result.date).to eq(existing_meal_record.date)
          expect(result.meal_type).to eq(3)
          expect(result.comment).to eq(existing_meal_record.comment)
        end
      end

      context "when updating only comment" do
        let(:comment_only_params) do
          Business::Food::Meal::Usecase::Params::Meal.new(
            :update,
            id: existing_meal_record.id,
            dish_id: existing_meal_record.dish_id,
            date: existing_meal_record.date,
            meal_type: existing_meal_record.meal_type,
            comment: "new comment only",
          )
        end

        it "updates only comment" do
          result = described_class.call(
            user_id: user_record.id,
            meal_params: comment_only_params,
          )

          expect(result.dish_id).to eq(existing_meal_record.dish_id)
          expect(result.date).to eq(existing_meal_record.date)
          expect(result.meal_type).to eq(existing_meal_record.meal_type)
          expect(result.comment).to eq("new comment only")
        end
      end

      context "when clearing comment" do
        let(:clear_comment_params) do
          Business::Food::Meal::Usecase::Params::Meal.new(
            :update,
            id: existing_meal_record.id,
            dish_id: existing_meal_record.dish_id,
            date: existing_meal_record.date,
            meal_type: existing_meal_record.meal_type,
            comment: "",
          )
        end

        it "clears comment" do
          result = described_class.call(
            user_id: user_record.id,
            meal_params: clear_comment_params,
          )

          expect(result.dish_id).to eq(existing_meal_record.dish_id)
          expect(result.date).to eq(existing_meal_record.date)
          expect(result.meal_type).to eq(existing_meal_record.meal_type)
          expect(result.comment).to eq("")
        end
      end

      context "when changing dish" do
        let(:new_dish_record) { FactoryBot.create(:dish, user: user_record) }
        let(:dish_change_params) do
          Business::Food::Meal::Usecase::Params::Meal.new(
            :update,
            id: existing_meal_record.id,
            dish_id: new_dish_record.id,
            date: existing_meal_record.date,
            meal_type: existing_meal_record.meal_type,
          )
        end

        it "updates dish" do
          result = described_class.call(
            user_id: user_record.id,
            meal_params: dish_change_params,
          )

          expect(result.dish_id).to eq(new_dish_record.id)
          expect(result.date).to eq(existing_meal_record.date)
          expect(result.meal_type).to eq(existing_meal_record.meal_type)
          expect(result.comment).to eq(existing_meal_record.comment)
        end
      end
    end

    context "when meal does not exist" do
      let(:non_existing_meal_params) do
        Business::Food::Meal::Usecase::Params::Meal.new(
          :update,
          id: 99_999,
          dish_id: dish_record.id,
          date: Date.today,
          meal_type: 1,
        )
      end

      it "raises error" do
        expect {
          described_class.call(
            user_id: user_record.id,
            meal_params: non_existing_meal_params,
          )
        }.to raise_error(ActiveRecord::RecordNotFound, /Meal with id 99999 not found/)
      end
    end

    context "with invalid dish_id" do
      let(:invalid_dish_params) do
        Business::Food::Meal::Usecase::Params::Meal.new(
          :update,
          id: existing_meal_record.id,
          dish_id: 999_999,
          date: existing_meal_record.date,
          meal_type: existing_meal_record.meal_type,
        )
      end

      it "raises error" do
        expect {
          described_class.call(
            user_id: user_record.id,
            meal_params: invalid_dish_params,
          )
        }.to raise_error("存在しない料理を紐付けることはできません。")
      end
    end
  end

  describe "validations" do
    context "when user_id is missing" do
      it "raises validation error" do
        expect {
          described_class.call(meal_params: valid_meal_params)
        }.to raise_error(/User can't be blank/)
      end
    end

    context "when meal_params is missing" do
      it "raises validation error" do
        expect {
          described_class.call(user_id: user_record.id)
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
  end
end
