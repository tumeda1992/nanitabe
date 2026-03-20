require "rails_helper"
require_relative "../../../graphql_auth_helper"

RSpec.describe "dishEffortLevels query", type: :request do
  def build_query
    <<~GRAPHQL
      query dishEffortLevels($mealPosition: Int!) {
        dishEffortLevels(mealPosition: $mealPosition) {
          id
          mealPosition
          minutes
          label
        }
      }
    GRAPHQL
  end

  before do
    DishEffortLevel.create!(meal_position: 1, minutes: 10, label: "ぱぱっとできる")
    DishEffortLevel.create!(meal_position: 1, minutes: 20, label: "普通")
    DishEffortLevel.create!(meal_position: 1, minutes: 50, label: "少し手間")
    DishEffortLevel.create!(meal_position: 2, minutes: 15, label: "メインのぱぱっと")
    DishEffortLevel.create!(meal_position: 3, minutes: 5, label: "副菜のぱぱっと")
    DishEffortLevel.create!(meal_position: 3, minutes: 10, label: "副菜の普通")
  end

  context "mealPosition: 1 (主食) を指定した場合" do
    it "主食のレコードのみ返すこと" do
      data = fetch_mutation_with_auth(build_query, { mealPosition: 1 })

      effort_levels = data["dishEffortLevels"]
      expect(effort_levels.map { |el| el["mealPosition"] }.uniq).to eq([1])
    end

    it "minutesの昇順で返ること" do
      data = fetch_mutation_with_auth(build_query, { mealPosition: 1 })

      effort_levels = data["dishEffortLevels"]
      expect(effort_levels.map { |el| el["minutes"] }).to eq([10, 20, 50])
    end
  end

  context "mealPosition: 3 (副菜) を指定した場合" do
    it "副菜のレコードのみ返すこと" do
      data = fetch_mutation_with_auth(build_query, { mealPosition: 3 })

      effort_levels = data["dishEffortLevels"]
      expect(effort_levels.map { |el| el["mealPosition"] }.uniq).to eq([3])
    end

    it "minutesの昇順で返ること" do
      data = fetch_mutation_with_auth(build_query, { mealPosition: 3 })

      effort_levels = data["dishEffortLevels"]
      expect(effort_levels.map { |el| el["minutes"] }).to eq([5, 10])
    end
  end

  context "対象データなしのmealPositionを指定した場合" do
    it "空配列が返ること" do
      data = fetch_mutation_with_auth(build_query, { mealPosition: 99 })

      expect(data["dishEffortLevels"]).to be_empty
    end
  end
end
