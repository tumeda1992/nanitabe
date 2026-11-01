require "rails_helper"
require_relative "../../graphql_auth_helper"

RSpec.describe "Dish effort level output", type: :request do
  let(:user) { FactoryBot.create(:user, id_param: "effort-output-user") }
  let(:effort) { DishEffortLevel.create!(meal_position: 2, minutes: 20, label: "normal") }

  [false, true].each do |assigned|
    it "returns #{assigned ? 'the stored ID' : 'null'} from detail and calendar queries" do
      dish = FactoryBot.create(:dish, user: user, meal_position: 2, dish_effort_level: assigned ? effort : nil)
      FactoryBot.create(:meal, user: user, dish: dish, date: Date.today)
      query = "query { dish(id: #{dish.id}) { dishEffortLevelId } mealsForCalender(startDate: \"#{Date.today}\", lastDate: \"#{Date.today}\") { meals { dish { dishEffortLevelId } } } }"
      result = fetch_mutation_with_auth(query, {}, user.id)
      expected = assigned ? effort.id : nil
      expect(result["dish"]["dishEffortLevelId"]).to eq(expected)
      expect(result["mealsForCalender"].first["meals"].first["dish"]["dishEffortLevelId"]).to eq(expected)
    end
  end
end
