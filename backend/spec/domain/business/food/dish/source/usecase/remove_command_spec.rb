require "rails_helper"
require_relative "../../../../../../support/factories/user_repository"

RSpec.describe Business::Food::Dish::Source::Usecase::RemoveCommand do
  let(:user_record) { find_or_create_user }
  let(:existing_source_record) { FactoryBot.create(:dish_source, user: user_record) }

  describe "#call" do
    context "with valid parameters" do
      it "removes source successfully" do
        source_id = existing_source_record.id
        user_id = existing_source_record.user_id

        expect(::DishSource.find_by(id: source_id, user_id: user_id)).not_to be_nil

        expect {
          described_class.call(
            user_id: user_id,
            source_id: source_id,
          )
        }.to change { ::DishSource.count }.by(-1)

        expect(::DishSource.find_by(id: source_id)).to be_nil
      end
    end

    context "when source does not exist" do
      it "raises error" do
        expect {
          described_class.call(
            user_id: user_record.id,
            source_id: 99_999,
          )
        }.to raise_error("指定したレシピ元は存在しません。")
      end
    end

    context "when source belongs to different user" do
      let(:other_user_record) { FactoryBot.create(:user, id_param: "different_user") }

      it "raises error" do
        expect {
          described_class.call(
            user_id: other_user_record.id,
            source_id: existing_source_record.id,
          )
        }.to raise_error("指定したレシピ元は存在しません。")
      end
    end
  end

  describe "validations" do
    context "when user_id is missing" do
      it "raises validation error" do
        expect {
          described_class.call(source_id: existing_source_record.id)
        }.to raise_error(/User can't be blank/)
      end
    end

    context "when source_id is missing" do
      it "raises validation error" do
        expect {
          described_class.call(user_id: user_record.id)
        }.to raise_error(/Source can't be blank/)
      end
    end

    context "when user_id is nil" do
      it "raises validation error" do
        expect {
          described_class.call(
            user_id: nil,
            source_id: existing_source_record.id,
          )
        }.to raise_error(/User can't be blank/)
      end
    end

    context "when source_id is nil" do
      it "raises validation error" do
        expect {
          described_class.call(
            user_id: user_record.id,
            source_id: nil,
          )
        }.to raise_error(/Source can't be blank/)
      end
    end
  end
end
