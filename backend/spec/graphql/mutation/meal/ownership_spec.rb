require "rails_helper"
require_relative "../../graphql_auth_helper"

RSpec.describe "Meal mutation ownership", type: :request do
  let(:owner) { FactoryBot.create(:user, id_param: "meal-owner") }
  let(:actor) { FactoryBot.create(:user, id_param: "meal-actor") }
  let(:dish) { FactoryBot.create(:dish, user: owner) }
  let!(:meal) { FactoryBot.create(:meal, user: owner, dish: dish) }
  let(:headers) { fetch_auth_header_values(existing_user_id: actor.id) }

  [false, true].each do |missing|
    context(missing ? "with a missing meal" : "with another user's meal") do
      let(:target_id) { missing ? Meal.maximum(:id) + 1 : meal.id }

      it "rejects updates without changing the meal" do
        snapshot = meal.attributes
        query = "mutation { updateMeal(input: {meal: {id: #{target_id}, date: \"2026-01-01\", mealType: 1}, dishId: #{dish.id}}) { mealId } }"
        expect { fetch_mutation(query, {}, headers: headers) }.to raise_error(StandardError)
        expect(meal.reload.attributes).to eq(snapshot)
      end

      it "rejects deletion without removing the meal" do
        query = "mutation { removeMeal(input: {mealId: #{target_id}}) { mealId } }"
        expect { fetch_mutation(query, {}, headers: headers) }.to raise_error(StandardError)
        expect(Meal.exists?(meal.id)).to be(true)
      end

      it "rolls back the new dish when the meal update is rejected" do
        source = FactoryBot.create(:dish_source, user: actor)
        headers # Authenticate before measuring business records.
        counts = [Dish.count, DishSource.count, DishSourceRelation.count, DishTag.count]
        query = "mutation { updateMealWithNewDish(input: {meal: {id: #{target_id}, date: \"2026-01-01\", mealType: 1}, dish: {name: \"new dish\", mealPosition: 1}, dishSource: {id: #{source.id}, type: #{source.type}}, dishSourceRelationDetail: {recipeBookPage: 1}, dishTags: [{content: \"new tag\"}]}) { mealId dishId } }"
        expect { fetch_mutation(query, {}, headers: headers) }.to raise_error(StandardError)
        expect([Dish.count, DishSource.count, DishSourceRelation.count, DishTag.count]).to eq(counts)
      end
    end
  end
end
