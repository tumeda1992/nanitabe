require "rails_helper"
require_relative "../../graphql_auth_helper"

RSpec.describe "Optional dish mutation arguments", type: :request do
  let(:user) { FactoryBot.create(:user, id_param: "optional-arguments-user") }
  let!(:dish) { FactoryBot.create(:dish, user: user) }
  let!(:source) { FactoryBot.create(:dish_source, user: user, type: 1) }
  let!(:relation) { FactoryBot.create(:dish_source_relation, dish: dish, dish_source: source, recipe_book_page: 42) }

  ["omitted", "null", "value"].each do |mode|
    it "accepts #{mode} for updateDish's source relation" do
      argument = case mode
                 when "omitted" then ""
                 when "null" then ", dishSourceRelation: null"
                 else ", dishSourceRelation: {dishId: #{dish.id}, dishSourceId: #{source.id}, dishSourceType: 1, dishSourceRelationDetail: {recipeBookPage: 7}}"
                 end
      query = "mutation { updateDish(input: {dish: {id: #{dish.id}, name: \"changed\"}#{argument}}) { dishId } }"
      result = fetch_mutation_with_auth(query, {}, user.id)
      expect(result["updateDish"]["dishId"]).to eq(dish.id)
      expect(dish.reload.name).to eq("changed")
      if mode == "value"
        expect(dish.dish_source_relation.recipe_book_page).to eq(7)
      else
        expect(dish.dish_source_relation).to be_nil
      end
    end

    it "accepts #{mode} for updateDishWithNewSource's relation detail" do
      argument = case mode
                 when "omitted" then ""
                 when "null" then ", dishSourceRelationDetail: null"
                 else ", dishSourceRelationDetail: {recipeBookPage: 7}"
                 end
      query = "mutation { updateDishWithNewSource(input: {dish: {id: #{dish.id}, name: \"changed\"}, dishSource: {name: \"new source\", type: 1}#{argument}}) { dishId dishSourceId } }"
      result = fetch_mutation_with_auth(query, {}, user.id)
      expect(result["updateDishWithNewSource"]["dishId"]).to eq(dish.id)
      expect(DishSource.find(result["updateDishWithNewSource"]["dishSourceId"]).name).to eq("new source")
      if mode == "value"
        expect(dish.reload.dish_source_relation.recipe_book_page).to eq(7)
      else
        expect(dish.reload.dish_source_relation).to be_nil
      end
    end
  end
end
