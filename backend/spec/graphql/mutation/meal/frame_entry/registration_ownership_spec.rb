require "rails_helper"
require_relative "../../../graphql_auth_helper"

RSpec.describe "Meal registration frame ownership", type: :request do
  let(:owner) { FactoryBot.create(:user, id_param: "registration-owner") }
  let(:actor) { FactoryBot.create(:user, id_param: "registration-actor") }
  let!(:dish) { FactoryBot.create(:dish, user: actor) }
  let!(:frame) { MealFrame.create!(user: owner, name: "foreign") }
  let!(:entry) { MealFrameEntry.create!(user: owner, meal_frame: frame, date: Date.today, meal_type: 1) }
  let(:headers) { fetch_auth_header_values(existing_user_id: actor.id) }

  [false, true].each do |missing|
    context(missing ? "missing entry" : "foreign entry") do
      let(:target_id) { missing ? MealFrameEntry.maximum(:id) + 1 : entry.id }
      ["addMeal", "addMealWithNewDish", "addMealWithNewDishAndNewSource"].each do |operation|
        it "rolls back every business record for #{operation}" do
          headers
          snapshot = entry.attributes
          models = [Meal, Dish, DishSource, DishSourceRelation, DishTag]
          counts = models.map(&:count)
          arguments = ["meal: {date: \"2026-01-01\", mealType: 1}", "frameEntryId: #{target_id}"]
          if operation == "addMeal"
            arguments << "dishId: #{dish.id}"
          else
            arguments << 'dish: {name: "created dish", mealPosition: 1}'
            arguments << 'dishTags: [{content: "created tag"}]'
            if operation == "addMealWithNewDishAndNewSource"
              arguments << 'dishSource: {name: "created source", type: 1}'
              arguments << "dishSourceRelationDetail: {recipeBookPage: 1}"
            end
          end
          query = "mutation { #{operation}(input: {#{arguments.join(', ')}}) { mealId } }"
          post("/graphql", params: { query: query, variables: {} }, as: :json, headers: headers)
          expect(response).to have_http_status(:not_found)
          expect(models.map(&:count)).to eq(counts)
          expect(entry.reload.attributes).to eq(snapshot)
        end
      end
    end
  end
end
