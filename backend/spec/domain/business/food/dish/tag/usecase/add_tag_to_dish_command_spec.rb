# frozen_string_literal: true

require "rails_helper"
require_relative "../../../../../../support/factories/user_repository"
require_relative "../../../../../../support/factories/dish_repository"

RSpec.describe Business::Food::Dish::Tag::Usecase::AddTagToDishCommand do
  let(:user_record) { find_or_create_user }
  let(:dish_record) { find_or_create_dish }

  describe "#call" do
    context "when adding a tag to an existing dish" do
      it "adds the tag to the dish" do
        described_class.call(
          user_id: user_record.id,
          dish_id: dish_record.id,
          tag_content: "白ワインに合う",
        )

        added_tag = ::DishTag.last
        expect(added_tag.dish_id).to eq(dish_record.id)
        expect(added_tag.user_id).to eq(user_record.id)
        expect(added_tag.content).to eq("白ワインに合う")
      end
    end

    context "when the dish does not exist" do
      it "raises an error" do
        expect {
          described_class.call(
            user_id: user_record.id,
            dish_id: 99_999,
            tag_content: "白ワインに合う",
          )
        }.to raise_error(RuntimeError, /99999/)
      end
    end
  end
end
