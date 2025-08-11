require "rails_helper"
require_relative "../../../../../support/factories/user_repository"
require_relative "../../../../../support/factories/dish_repository"

RSpec.describe Business::Food::Dish::Usecase::UpdateCommand do
  let(:user_record) { find_or_create_user }
  let(:existing_dish_record) { find_or_create_dish }
  let(:dish_name) { "updated_dish_name" }
  let(:normalized_dish_name) { "updated_dish_name_normalized" }
  let(:meal_position) { 2 }
  let(:comment) { "updated_comment" }

  let(:valid_dish_params) do
    Business::Food::Dish::Usecase::Params::Dish.new(
      :update,
      id: existing_dish_record.id,
      name: dish_name,
      meal_position: meal_position,
      comment: comment
    )
  end

  before do
    allow(Business::Dish::Word::Normalize::Command::NormalizeCommand)
      .to receive(:call)
      .with(string_sequence: dish_name)
      .and_return(normalized_dish_name)
  end

  describe "#call" do
    context "with valid parameters" do
      it "updates dish successfully and returns Business::Food::Dish::Root" do
        result = described_class.call(
          user_id: user_record.id,
          dish_params: valid_dish_params
        )

        expect(result).to be_a(Business::Food::Dish::Root)
        expect(result.id).to eq(existing_dish_record.id)
        expect(result.user_id).to eq(user_record.id)
        expect(result.name).to eq(dish_name)
        expect(result.normalized_name).to eq(normalized_dish_name)
        expect(result.meal_position).to eq(meal_position)
        expect(result.comment).to eq(comment)
      end

      it "updates dish in database" do
        described_class.call(
          user_id: user_record.id,
          dish_params: valid_dish_params
        )

        updated_dish = ::Dish.find(existing_dish_record.id)
        expect(updated_dish.name).to eq(dish_name)
        expect(updated_dish.normalized_name).to eq(normalized_dish_name)
        expect(updated_dish.meal_position).to eq(meal_position)
        expect(updated_dish.comment).to eq(comment)
      end

      context "when updating only name" do
        let(:name_only_params) do
          Business::Food::Dish::Usecase::Params::Dish.new(
            :update,
            id: existing_dish_record.id,
            name: dish_name
          )
        end

        it "updates only name" do
          result = described_class.call(
            user_id: user_record.id,
            dish_params: name_only_params
          )

          expect(result.name).to eq(dish_name)
          expect(result.normalized_name).to eq(normalized_dish_name)
          expect(result.meal_position).to eq(existing_dish_record.meal_position)
          expect(result.comment).to eq(existing_dish_record.comment)
        end
      end

      context "when updating only meal_position" do
        let(:position_only_params) do
          Business::Food::Dish::Usecase::Params::Dish.new(
            :update,
            id: existing_dish_record.id,
            meal_position: meal_position
          )
        end

        it "updates only meal_position" do
          result = described_class.call(
            user_id: user_record.id,
            dish_params: position_only_params
          )

          expect(result.name).to eq(existing_dish_record.name)
          expect(result.meal_position).to eq(meal_position)
          expect(result.comment).to eq(existing_dish_record.comment)
        end
      end

      context "when updating only comment" do
        let(:comment_only_params) do
          Business::Food::Dish::Usecase::Params::Dish.new(
            :update,
            id: existing_dish_record.id,
            comment: comment
          )
        end

        it "updates only comment" do
          result = described_class.call(
            user_id: user_record.id,
            dish_params: comment_only_params
          )

          expect(result.name).to eq(existing_dish_record.name)
          expect(result.meal_position).to eq(existing_dish_record.meal_position)
          expect(result.comment).to eq(comment)
        end
      end

      context "when clearing comment" do
        let(:clear_comment_params) do
          Business::Food::Dish::Usecase::Params::Dish.new(
            :update,
            id: existing_dish_record.id,
            comment: ""
          )
        end

        it "clears comment" do
          result = described_class.call(
            user_id: user_record.id,
            dish_params: clear_comment_params
          )

          expect(result.name).to eq(existing_dish_record.name)
          expect(result.meal_position).to eq(existing_dish_record.meal_position)
          expect(result.comment).to eq("")
        end
      end
    end

    context "when dish does not exist" do
      let(:non_existing_dish_params) do
        Business::Food::Dish::Usecase::Params::Dish.new(
          :update,
          id: 99999,
          name: dish_name
        )
      end

      it "raises error" do
        expect {
          described_class.call(
            user_id: user_record.id,
            dish_params: non_existing_dish_params
          )
        }.to raise_error("指定した料理は存在しません。")
      end
    end
  end

  describe "validations" do
    context "when user_id is missing" do
      it "raises validation error" do
        expect {
          described_class.call(dish_params: valid_dish_params)
        }.to raise_error(/User can't be blank/)
      end
    end

    context "when dish_params is missing" do
      it "raises validation error" do
        expect {
          described_class.call(user_id: user_record.id)
        }.to raise_error(/Dish params can't be blank/)
      end
    end

    context "when user_id is nil" do
      it "raises validation error" do
        expect {
          described_class.call(
            user_id: nil,
            dish_params: valid_dish_params
          )
        }.to raise_error(/User can't be blank/)
      end
    end

    context "when dish_params is nil" do
      it "raises validation error" do
        expect {
          described_class.call(
            user_id: user_record.id,
            dish_params: nil
          )
        }.to raise_error(/Dish params can't be blank/)
      end
    end
  end
end