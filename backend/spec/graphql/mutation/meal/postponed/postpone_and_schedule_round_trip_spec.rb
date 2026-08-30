require "rails_helper"
require_relative "../../../graphql_auth_helper"
require_relative "../../../../support/factories/user_repository"
require_relative "../../../../support/factories/dish_repository"

# PostponedMeal は退避エンティティであり、延期→復元の1往復で dish_id / meal_type / comment が
# 元の食事と一致することは、全量保存という設計判断そのものに対する回帰テストである。
# 参照: .steering/2026/202608/20260829-add-pending-dish-pool/implementation_review.md 論点1・論点2
RSpec.describe "postponeMeal -> schedulePostponedMeal round trip", type: :request do
  let(:user_record) { find_or_create_user }
  let(:dish_record) { find_or_create_dish }

  def build_postpone_mutation
    <<~GRAPHQL
      mutation postponeMeal($mealId: Int!) {
        postponeMeal(input: { mealId: $mealId }) {
          postponedMealId
        }
      }
    GRAPHQL
  end

  def build_schedule_mutation
    <<~GRAPHQL
      mutation schedulePostponedMeal($postponedMealId: Int!, $date: ISO8601Date!) {
        schedulePostponedMeal(input: { postponedMealId: $postponedMealId, date: $date }) {
          mealId
        }
      }
    GRAPHQL
  end

  context "when the original meal has a comment" do
    let!(:original_meal) do
      Meal.create!(
        user: user_record,
        dish: dish_record,
        date: Date.today,
        meal_type: 3,
        comment: "急遽外食",
      )
    end

    it "restores dish_id, meal_type, and comment onto the newly scheduled meal" do
      # NOTE: fetch_mutation_with_auth はユーザーごとに毎回ログインし直すため、
      # 同一ユーザーで2回mutationを呼ぶとloginUserLoginがuseridを受け付けずエラーになる
      # （devise_token_authのlogin mutationの既存の制約）。ここでは認証headerを1回だけ取得して使い回す。
      auth_headers = fetch_auth_header_values(existing_user_id: user_record.id)

      postpone_result = fetch_mutation(
        build_postpone_mutation,
        { mealId: original_meal.id },
        headers: auth_headers,
      )
      postponed_meal_id = postpone_result["postponeMeal"]["postponedMealId"]

      schedule_result = fetch_mutation(
        build_schedule_mutation,
        { postponedMealId: postponed_meal_id, date: "2026-09-15" },
        headers: auth_headers,
      )
      restored_meal = Meal.find(schedule_result["schedulePostponedMeal"]["mealId"])

      expect(restored_meal.dish_id).to eq(original_meal.dish_id)
      expect(restored_meal.meal_type).to eq(original_meal.meal_type)
      expect(restored_meal.comment).to eq(original_meal.comment)
      expect(restored_meal.date).to eq(Date.parse("2026-09-15"))
    end
  end

  context "when the original meal has no comment" do
    let!(:original_meal) do
      Meal.create!(
        user: user_record,
        dish: dish_record,
        date: Date.today,
        meal_type: 2,
        comment: nil,
      )
    end

    it "keeps the comment NULL through the round trip" do
      auth_headers = fetch_auth_header_values(existing_user_id: user_record.id)

      postpone_result = fetch_mutation(
        build_postpone_mutation,
        { mealId: original_meal.id },
        headers: auth_headers,
      )
      postponed_meal_id = postpone_result["postponeMeal"]["postponedMealId"]

      schedule_result = fetch_mutation(
        build_schedule_mutation,
        { postponedMealId: postponed_meal_id, date: "2026-09-16" },
        headers: auth_headers,
      )
      restored_meal = Meal.find(schedule_result["schedulePostponedMeal"]["mealId"])

      expect(restored_meal.dish_id).to eq(original_meal.dish_id)
      expect(restored_meal.meal_type).to eq(original_meal.meal_type)
      expect(restored_meal.comment).to be_nil
    end
  end
end
