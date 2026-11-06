require "rails_helper"
require_relative "../../graphql_auth_helper"

RSpec.describe "Updating a meal with a new dish without a source", type: :request do
  let(:user) { FactoryBot.create(:user, id_param: "fr022-owner") }
  let!(:meal) { FactoryBot.create(:meal, user: user, dish: FactoryBot.create(:dish, user: user)) }
  let(:headers) { fetch_auth_header_values(existing_user_id: user.id) }

  ["", "dishSource: null"].each do |source_argument|
    it "accepts #{source_argument.empty? ? 'omission' : 'explicit null'} without creating a source or relation" do
      headers
      source_count = DishSource.count
      relation_count = DishSourceRelation.count
      query = <<~GRAPHQL
        mutation {
          updateMealWithNewDish(input: {
            meal: {id: #{meal.id}, date: "2026-10-11", mealType: 3},
            dish: {name: "出典なし料理", mealPosition: 1}, #{source_argument}
          }) { mealId dishId }
        }
      GRAPHQL
      result = fetch_mutation(query, {}, headers: headers)["updateMealWithNewDish"]
      expect(result["mealId"]).to eq(meal.id)
      expect(meal.reload.dish_id).to eq(result["dishId"])
      expect(meal.dish.name).to eq("出典なし料理")
      expect(meal.dish.user_id).to eq(user.id)
      expect(meal.dish.dish_source_relation).to be_nil
      expect(DishSource.count).to eq(source_count)
      expect(DishSourceRelation.count).to eq(relation_count)
    end
  end

  it "rolls back the source-less new dish for an unauthorized meal" do
    other = FactoryBot.create(:user, id_param: "fr022-other")
    foreign = FactoryBot.create(:meal, user: other, dish: FactoryBot.create(:dish, user: other))
    headers
    count = Dish.count
    original = foreign.attributes
    query = "mutation { updateMealWithNewDish(input: {meal: {id: #{foreign.id}, date: \"2026-10-11\", mealType: 3}, dish: {name: \"拒否される料理\", mealPosition: 1}}) { dishId } }"
    expect { fetch_mutation(query, {}, headers: headers) }.to raise_error(StandardError)
    expect(Dish.count).to eq(count)
    expect(foreign.reload.attributes).to eq(original)
  end
end
