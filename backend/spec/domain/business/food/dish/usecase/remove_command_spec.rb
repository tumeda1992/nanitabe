require "rails_helper"
require_relative "../../../../../support/factories/user_repository"
require_relative "../../../../../support/factories/dish_repository"

RSpec.describe Business::Food::Dish::Usecase::RemoveCommand do
  let(:user_record) { find_or_create_user }
  let(:existing_dish_record) { find_or_create_dish }

  describe "#call" do
    context "with valid parameters" do
      it "removes dish successfully" do
        dish_id = existing_dish_record.id
        user_id = existing_dish_record.user_id
        
        expect(::Dish.find_by(id: dish_id, user_id: user_id)).not_to be_nil
        
        expect {
          described_class.call(
            user_id: user_id,
            dish_id: dish_id
          )
        }.to change { ::Dish.count }.by(-1)

        expect(::Dish.find_by(id: dish_id)).to be_nil
      end
    end

    context "when dish does not exist" do
      it "raises error" do
        expect {
          described_class.call(
            user_id: user_record.id,
            dish_id: 99999
          )
        }.to raise_error("指定した料理は存在しません。")
      end
    end

    context "when dish belongs to different user" do
      let(:other_user_record) { FactoryBot.create(:user, id_param: "different_user") }

      it "raises error" do
        expect {
          described_class.call(
            user_id: other_user_record.id,
            dish_id: existing_dish_record.id
          )
        }.to raise_error("指定した料理は存在しません。")
      end
    end
  end

  describe "validations" do
    context "when user_id is missing" do
      it "raises validation error" do
        expect {
          described_class.call(dish_id: existing_dish_record.id)
        }.to raise_error(/User can't be blank/)
      end
    end

    context "when dish_id is missing" do
      it "raises validation error" do
        expect {
          described_class.call(user_id: user_record.id)
        }.to raise_error(/Dish can't be blank/)
      end
    end

    context "when user_id is nil" do
      it "raises validation error" do
        expect {
          described_class.call(
            user_id: nil,
            dish_id: existing_dish_record.id
          )
        }.to raise_error(/User can't be blank/)
      end
    end

    context "when dish_id is nil" do
      it "raises validation error" do
        expect {
          described_class.call(
            user_id: user_record.id,
            dish_id: nil
          )
        }.to raise_error(/Dish can't be blank/)
      end
    end
  end
end