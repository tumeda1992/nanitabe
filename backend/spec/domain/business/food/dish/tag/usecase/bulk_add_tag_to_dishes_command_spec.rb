# frozen_string_literal: true

require "rails_helper"
require_relative "../../../../../../support/factories/user_repository"
require_relative "../../../../../../support/factories/dish_repository"

RSpec.describe Business::Food::Dish::Tag::Usecase::BulkAddTagToDishesCommand do
  let(:user_record) { find_or_create_user }
  let(:dish_record) { find_or_create_dish }
  let(:dish_record_2) { find_or_create_dish_2 }

  describe "#call" do
    context "when adding a tag to multiple existing dishes" do
      it "adds the tag to all dishes" do
        described_class.call(
          user_id: user_record.id,
          dish_ids: [dish_record.id, dish_record_2.id],
          tag_content: "白ワインに合う",
        )

        added_tags = ::DishTag.last(2)
        expect(added_tags.map(&:dish_id)).to contain_exactly(dish_record.id, dish_record_2.id)
        expect(added_tags.map(&:content)).to all(eq("白ワインに合う"))
      end
    end

    context "when one of the dish_ids does not exist" do
      it "raises an error and rolls back the transaction" do
        expect {
          described_class.call(
            user_id: user_record.id,
            dish_ids: [dish_record.id, 99_999],
            tag_content: "白ワインに合う",
          )
        }.to raise_error(RuntimeError)

        expect(::DishTag.where(dish_id: dish_record.id, content: "白ワインに合う")).to be_empty
      end
    end

    context "when dish_ids is empty" do
      it "raises a validation error" do
        expect {
          described_class.call(
            user_id: user_record.id,
            dish_ids: [],
            tag_content: "白ワインに合う",
          )
        }.to raise_error(StandardError)
      end
    end

    context "when tag_content is empty" do
      it "raises a validation error" do
        expect {
          described_class.call(
            user_id: user_record.id,
            dish_ids: [dish_record.id],
            tag_content: "",
          )
        }.to raise_error(StandardError)
      end
    end
  end
end
