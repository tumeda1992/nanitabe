require "rails_helper"
require_relative "../../../../../support/factories/user_repository"

RSpec.describe Business::Food::Dish::Usecase::AddCommand do
  let(:user_record) { find_or_create_user }
  let(:dish_name) { "test_dish" }
  let(:normalized_dish_name) { "test_dish_normalized" }
  let(:meal_position) { 1 }
  let(:comment) { "test_comment" }

  let(:valid_dish_params) do
    Business::Food::Dish::Usecase::Params::Dish.new(
      :create,
      name: dish_name,
      meal_position: meal_position,
      comment: comment
    )
  end

  before do
    # Mock the normalize command
    allow(Business::Dish::Word::Normalize::Command::NormalizeCommand)
      .to receive(:call)
      .with(string_sequence: dish_name)
      .and_return(normalized_dish_name)
  end

  describe "#call" do
    context "with valid parameters" do
      it "creates dish successfully and returns Business::Food::Dish::Root" do
        result = described_class.call(
          user_id: user_record.id,
          dish_params: valid_dish_params
        )

        expect(result).to be_a(Business::Food::Dish::Root)
        expect(result.user_id).to eq(user_record.id)
        expect(result.name).to eq(dish_name)
        expect(result.normalized_name).to eq(normalized_dish_name)
        expect(result.meal_position).to eq(meal_position)
        expect(result.comment).to eq(comment)
      end

      it "saves dish to database" do
        expect {
          described_class.call(
            user_id: user_record.id,
            dish_params: valid_dish_params
          )
        }.to change { ::Dish.count }.by(1)

        created_dish = ::Dish.last
        expect(created_dish.user_id).to eq(user_record.id)
        expect(created_dish.name).to eq(dish_name)
        expect(created_dish.normalized_name).to eq(normalized_dish_name)
        expect(created_dish.meal_position).to eq(meal_position)
        expect(created_dish.comment).to eq(comment)
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

    context "when dish_param is missing" do
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

    context "when dish_param is nil" do
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
