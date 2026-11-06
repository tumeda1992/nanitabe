require "rails_helper"
require_relative "../../graphql_auth_helper"

RSpec.describe "Updating existing dish tag content", type: :request do
  it "returns success and exposes the changed value under the same ID when queried again" do
    owner = FactoryBot.create(:user, id_param: "tag-graphql-owner")
    dish = FactoryBot.create(:dish, user: owner)
    tag = FactoryBot.create(:dish_tag, user: owner, dish: dish, content: "alpha", normalized_content: "alpha")
    mutation = <<~GRAPHQL
      mutation updateDish($dish: DishForUpdate!, $dishTags: [Tag!]) {
        updateDish(input: {dish: $dish, dishTags: $dishTags}) { dishId }
      }
    GRAPHQL
    result = fetch_mutation_with_auth(mutation, {
      dish: { id: dish.id, name: dish.name }, dishTags: [{ id: tag.id, content: "ぶた" }]
    }, owner.id)
    expect(result["updateDish"]["dishId"]).to eq(dish.id)

    # The search projection preloads sources; include a real relation in this fixture.
    source = FactoryBot.create(:dish_source, user: owner)
    FactoryBot.create(:dish_source_relation, dish: FactoryBot.create(:dish, user: owner), dish_source: source)

    query = <<~GRAPHQL
      query {
        existingDishesForRegisteringWithMeal { id tags { id content } }
      }
    GRAPHQL
    data = fetch_mutation_with_auth(query, {}, owner.id)
    saved = data["existingDishesForRegisteringWithMeal"].find { |item| item["id"] == dish.id }
    expect(saved["tags"]).to eq([{ "id" => tag.id, "content" => "ぶた" }])
    expect(tag.reload.normalized_content).to eq("ブタ")
  end
end
