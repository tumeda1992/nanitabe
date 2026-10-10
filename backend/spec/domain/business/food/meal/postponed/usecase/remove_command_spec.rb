require "rails_helper"
require_relative "../../../../../../support/factories/user_repository"
require_relative "../../../../../../support/factories/dish_repository"

RSpec.describe Business::Food::Meal::Postponed::Usecase::RemoveCommand do
  let(:user_record) { find_or_create_user }
  let(:dish_record) { find_or_create_dish }
  let!(:postponed_meal_record) do
    PostponedMeal.create!(user: user_record, dish: dish_record, meal_type: 3)
  end

  describe "#call" do
    context "when postponed_meal_id exists" do
      it "destroys the postponed meal record" do
        expect {
          described_class.call(user_id: user_record.id, postponed_meal_id: postponed_meal_record.id)
        }.to change { PostponedMeal.count }.by(-1)

        expect(PostponedMeal.exists?(postponed_meal_record.id)).to be(false)
      end
    end

    context "when postponed_meal_id does not exist" do
      it "raises an error and does not change any records" do
        expect {
          expect {
            described_class.call(user_id: user_record.id, postponed_meal_id: 99_999)
          }.to raise_error(/指定した延期された食事は存在しません。/)
        }.not_to(change { PostponedMeal.count })
      end
    end

    context "validations" do
      context "when postponed_meal_id is missing" do
        it "raises validation error" do
          expect {
            described_class.call(user_id: user_record.id)
          }.to raise_error(/Postponed meal can't be blank/)
        end
      end
    end
  end
end
