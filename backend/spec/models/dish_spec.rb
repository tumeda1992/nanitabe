require "rails_helper"
require_relative "../support/factories/user_repository"

RSpec.describe Dish, type: :model do
  describe ".build_existing_root_from_id" do
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
      it "returns Business::Food::Dish::Root with correct attributes" do
        result = described_class.build_existing_root_from_id(existing_dish.id)

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
          result = described_class.build_existing_root_from_id(existing_dish.id)

          expect(result.source_id).to eq(dish_source.id)
        end
      end

      context "when dish has no associated dish_source" do
        it "sets source_id to nil" do
          result = described_class.build_existing_root_from_id(existing_dish.id)

          expect(result.source_id).to be_nil
        end
      end
    end

    context "when dish does not exist" do
      it "returns nil" do
        result = described_class.build_existing_root_from_id(99999)

        expect(result).to be_nil
      end
    end

    context "when id is nil" do
      it "returns nil" do
        result = described_class.build_existing_root_from_id(nil)

        expect(result).to be_nil
      end
    end
  end
end