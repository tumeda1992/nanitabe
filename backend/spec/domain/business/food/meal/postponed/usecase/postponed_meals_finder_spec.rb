require "rails_helper"
require_relative "../../../../../../support/factories/user_repository"
require_relative "../../../../../../support/factories/dish_repository"

RSpec.describe Business::Food::Meal::Postponed::Usecase::PostponedMealsFinder do
  let(:user_record) { find_or_create_user }
  let(:dish_record) { find_or_create_dish }

  describe "#fetch" do
    context "when the user has postponed meals" do
      let!(:older_postponed_meal) do
        record = PostponedMeal.create!(user: user_record, dish: dish_record, meal_type: 3)
        record.update_column(:created_at, 2.days.ago)
        record
      end
      let!(:newer_postponed_meal) do
        record = PostponedMeal.create!(user: user_record, dish: dish_record, meal_type: 2, comment: "急遽外食")
        record.update_column(:created_at, 1.day.ago)
        record
      end

      it "returns postponed meals ordered by created_at desc" do
        result = described_class.call(user_id: user_record.id)

        expect(result.map(&:id)).to eq([newer_postponed_meal.id, older_postponed_meal.id])
      end

      it "includes dish_name and comment resolved from the record" do
        result = described_class.call(user_id: user_record.id)

        expect(result.first.dish_name).to eq(dish_record.name)
        expect(result.first.dish_id).to eq(dish_record.id)
        expect(result.first.meal_type).to eq(2)
        expect(result.first.comment).to eq("急遽外食")
      end

      it "returns a NULL comment as nil when the postponed meal has no comment" do
        result = described_class.call(user_id: user_record.id)

        older_item = result.find { |item| item.id == older_postponed_meal.id }
        expect(older_item.comment).to be_nil
      end
    end

    context "when another user has postponed meals" do
      let(:other_user) { User.create!(id_param: "other_user_param_finder") }
      let!(:other_postponed_meal) do
        PostponedMeal.create!(user: other_user, dish: dish_record, meal_type: 1)
      end

      it "does not include other users' postponed meals" do
        result = described_class.call(user_id: user_record.id)

        expect(result).to eq([])
      end
    end

    context "when the user has no postponed meals" do
      it "returns an empty array" do
        result = described_class.call(user_id: user_record.id)

        expect(result).to eq([])
      end
    end
  end
end
