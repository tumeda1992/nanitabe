require "rails_helper"
require_relative "../../../graphql_auth_helper"
require_relative "../../../../support/factories/user_repository"
require_relative "../../../../support/factories/dish_repository"

module Mutations::Dish::Tag
  RSpec.describe BulkAddTagToDishes, type: :request do
    def build_mutation
      <<~GRAPHQL
        mutation bulkAddTagToDishes(
          $dishIds: [Int!]!
          $tag: String!
        ) {
          bulkAddTagToDishes(input: {
            dishIds: $dishIds
            tag: $tag
          }) {
            dishIds
          }
        }
      GRAPHQL
    end

    let(:user_record) { find_or_create_user }
    let(:dish_record) { find_or_create_dish }

    context "when bulk adding a tag to dishes" do
      it "adding succeeds" do
        variables = {
          dishIds: [dish_record.id],
          tag: "白ワインに合う",
        }
        fetch_mutation_with_auth(build_mutation, variables, user_record.id)

        added_tag = ::DishTag.last
        expect(added_tag.dish_id).to eq(dish_record.id)
        expect(added_tag.content).to eq("白ワインに合う")
      end
    end
  end
end
