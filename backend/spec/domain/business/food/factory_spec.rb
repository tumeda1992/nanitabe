require "rails_helper"
require_relative "../../../support/factories/user_repository"
require_relative "../../../support/factories/dish_repository"

RSpec.describe Business::Food::Dish::Factory do
  describe ".build" do
    context "with valid parameters" do
      let(:user_id) { 1 }
      let(:name) { "かつ丼" }
      let(:meal_position) { 1 }
      let(:comment) { "delicious" }

      before do
        allow(Business::Dish::Word::Normalize::Command::NormalizeCommand)
          .to receive(:call)
          .with(string_sequence: name)
          .and_return("カツ丼")
      end

      it "returns a valid Business::Food::Dish::Root object" do
        dish = described_class.build(user_id, name, meal_position, comment: comment)

        expect(dish).to be_a(Business::Food::Dish::Root)
        expect(dish.user_id).to eq(user_id)
        expect(dish.name).to eq(name)
        expect(dish.normalized_name).to eq("カツ丼")
        expect(dish.meal_position).to eq(meal_position)
        expect(dish.comment).to eq(comment)
      end

    end

    context "with invalid parameters" do
      it "raises error when validation fails" do
        expect { described_class.build(nil, "test", 1) }.to raise_error
      end
    end
  end

  describe ".build_existing_from_id" do
    context "when building existing dish from database" do
      let(:user_record) { find_or_create_user }
      let(:dish_record) { find_or_create_dish }

      it "builds Business::Food::Dish::Root from existing data" do
        # Ensure dish belongs to user
        dish_record.update!(user_id: user_record.id)
        
        dish = described_class.build_existing_from_id(dish_record.id)

        expect(dish).to be_a(Business::Food::Dish::Root)
        expect(dish.id).to eq(dish_record.id)
        expect(dish.user_id).to eq(dish_record.user_id)
        expect(dish.name).to eq(dish_record.name)
        expect(dish.normalized_name).to eq(dish_record.normalized_name)
        expect(dish.meal_position).to eq(dish_record.meal_position)
        expect(dish.comment).to eq(dish_record.comment)
      end
    end
  end
end
