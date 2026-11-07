require "rails_helper"

RSpec.describe "Meal dish ownership" do
  let(:owner) { FactoryBot.create(:user, id_param: "dish-reference-owner") }
  let(:actor) { FactoryBot.create(:user, id_param: "dish-reference-actor") }
  let(:foreign_dish) { FactoryBot.create(:dish, user: owner) }
  let(:own_dish) { FactoryBot.create(:dish, user: actor) }

  it "rejects creating a meal with a foreign dish without storing a meal" do
    params = Business::Food::Meal::Usecase::Params::Meal.new(dish_id: foreign_dish.id, date: Date.today, meal_type: 1)
    expect {
      Business::Food::Meal::Usecase::AddCommand.call(user_id: actor.id, meal_params: params)
    }.to raise_error("存在しない料理を紐付けることはできません。")
    expect(Meal.count).to eq(0)
  end

  it "rejects replacing an owned meal's dish with a foreign dish" do
    meal = FactoryBot.create(:meal, user: actor, dish: own_dish)
    snapshot = meal.attributes
    params = Business::Food::Meal::Usecase::Params::Meal.new(:update, id: meal.id, dish_id: foreign_dish.id, date: meal.date, meal_type: meal.meal_type)
    expect {
      Business::Food::Meal::Usecase::UpdateCommand.call(user_id: actor.id, meal_params: params)
    }.to raise_error("存在しない料理を紐付けることはできません。")
    expect(meal.reload.attributes).to eq(snapshot)
  end

  it "rejects creating a postponed meal with a foreign dish" do
    expect {
      Business::Food::Meal::Postponed::Usecase::AddCommand.call(user_id: actor.id, dish_id: foreign_dish.id, meal_type: 1)
    }.to raise_error("存在しない料理を紐付けることはできません。")
    expect(PostponedMeal.count).to eq(0)
  end

  it "does not expose a foreign dish through a preexisting cross-owner meal" do
    meal = FactoryBot.create(:meal, user: actor, dish: foreign_dish, date: Date.today)
    result = Business::Food::Meal::Usecase::DateMealsFinder.call(access_user_id: actor.id, start_date: Date.today, last_date: Date.today)
    expect(result).to be_empty
    expect(Meal.exists?(meal.id)).to be(true)
  end

  it "does not expose a foreign dish through a preexisting postponed meal" do
    postponed = PostponedMeal.create!(user: actor, dish: foreign_dish, meal_type: 1)
    result = Business::Food::Meal::Postponed::Usecase::PostponedMealsFinder.call(user_id: actor.id)
    expect(result).to be_empty
    expect(PostponedMeal.exists?(postponed.id)).to be(true)
  end
end
