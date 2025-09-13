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
        expect { described_class.build(nil, "test", 1) }.to raise_error(Business::Base::Values::InvalidAttributeError)
      end
    end
  end

  describe ".build_existing_from_id" do
    let(:user_record) { find_or_create_user }
    let(:dish_source) { FactoryBot.create(:dish_source, user: user_record) }
    let(:existing_dish) do
      FactoryBot.create(
        :dish,
        user: user_record,
        name: "test_dish",
        normalized_name: "test_dish_normalized",
        meal_position: 1,
        comment: "test_comment"
      )
    end

    context "when dish exists" do
      it "builds Business::Food::Dish::Root from existing data" do
        result = described_class.build_existing_from_id(existing_dish.id)

        expect(result).to be_a(Business::Food::Dish::Root)
        expect(result.id).to eq(existing_dish.id)
        expect(result.user_id).to eq(existing_dish.user_id)
        expect(result.name).to eq(existing_dish.name)
        expect(result.normalized_name).to eq(existing_dish.normalized_name)
        expect(result.meal_position).to eq(existing_dish.meal_position)
        expect(result.comment).to eq(existing_dish.comment)
      end

      context "when dish has associated dish_source" do
        before do
          existing_dish.update!(dish_source: dish_source)
        end

        it "includes source_id in the root" do
          result = described_class.build_existing_from_id(existing_dish.id)

          expect(result.source_id).to eq(dish_source.id)
        end
      end

      context "when dish has no associated dish_source" do
        it "sets source_id to nil" do
          result = described_class.build_existing_from_id(existing_dish.id)

          expect(result.source_id).to be_nil
        end
      end
    end

    context "when dish does not exist" do
      it "returns nil" do
        result = described_class.build_existing_from_id(99999)

        expect(result).to be_nil
      end
    end

    context "when id is nil" do
      it "returns nil" do
        result = described_class.build_existing_from_id(nil)

        expect(result).to be_nil
      end
    end

    context "delegates to Dish.build_existing_root_from_id" do
      it "calls Dish.build_existing_root_from_id with correct parameter" do
        expect(::Dish).to receive(:build_existing_root_from_id).with(existing_dish.id).and_call_original

        described_class.build_existing_from_id(existing_dish.id)
      end
    end
  end
end
