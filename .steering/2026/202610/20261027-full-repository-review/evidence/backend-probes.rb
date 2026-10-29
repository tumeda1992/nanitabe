require '/app/spec/rails_helper'
require '/app/spec/graphql/graphql_auth_helper'
RSpec.describe 'Full repository review probes', type: :request do
  let!(:a) { User.create!(id_param: 'review-user-a') }
  let!(:b) { User.create!(id_param: 'review-user-b') }
  let!(:dish) { Dish.create!(user: b, name: 'other-private-dish', meal_position: 2) }
  it 'allows user A to register a meal referring to user B dish and read its name' do
    query = 'mutation { addMeal(input: { dishId: '+dish.id.to_s+', meal: {date: "2026-10-27", mealType: 3} }) { mealId } }'
    data = fetch_mutation_with_auth(query, {}, a.id)
    expect(Meal.find(data['addMeal']['mealId']).dish_id).to eq(dish.id)
    result = Business::Food::Meal::Usecase::DateMealsFinder.call(access_user_id: a.id, start_date: Date.new(2026,10,27), last_date: Date.new(2026,10,27))
    expect(result.first[:meals].first[:dish][:name]).to eq('other-private-dish')
  end
  it 'accepts another user frame in a new pattern and exposes its name' do
    frame = MealFrame.create!(user: b, name: 'private-frame')
    query = 'mutation { addMealFramePattern(input: { mealFramePattern: {name: "mine", entries: [{dayOffset: 1, mealType: 3, mealFrameId: '+frame.id.to_s+'}] } }) { mealFramePatternId } }'
    headers = fetch_auth_header_values(existing_user_id: a.id)
    fetch_mutation(query, {}, headers: headers)
    data = fetch_mutation('query { mealFramePatterns { entries { mealFrameName } } }', {}, headers: headers)
    expect(data['mealFramePatterns'].first['entries'].first['mealFrameName']).to eq('private-frame')
  end
  it 'leaves a populated frame at its old date when moving its meal' do
    frame = MealFrame.create!(user: b, name: 'frame')
    meal = Meal.create!(user: b, dish:, date: Date.new(2026,10,27), meal_type: 3)
    entry = MealFrameEntry.create!(user: b, meal_frame: frame, meal:, date: meal.date, meal_type: 3)
    params = Business::Food::Meal::Usecase::Params::Meal.new(id: meal.id, dish_id: dish.id, date: Date.new(2026,10,28), meal_type: 3)
    Business::Food::Meal::Usecase::UpdateCommand.call(user_id: b.id, meal_params: params)
    expect(entry.reload.date).to eq(Date.new(2026,10,27))
    expect(entry.meal_id).to eq(meal.id)
    expect(Business::Food::Meal::Usecase::DateMealsFinder.call(access_user_id: b.id, start_date: Date.new(2026,10,27), last_date: Date.new(2026,10,27))).to eq([])
  end
  it 'allows two frames to refer to the same meal' do
    frame = MealFrame.create!(user: b, name: 'frame')
    meal = Meal.create!(user: b, dish:, date: Date.new(2026,10,27), meal_type: 3)
    entries = 2.times.map { MealFrameEntry.create!(user: b, meal_frame: frame, date: meal.date, meal_type: 3) }
    entries.each { |entry| Business::Food::Meal::Frame::Entry::Usecase::FillWithMealCommand.call(user_id: b.id, meal_frame_entry_id: entry.id, meal_id: meal.id) }
    expect(MealFrameEntry.where(meal_id: meal.id).count).to eq(2)
  end
  it 'permits unauthenticated admin page reads' do
    get '/admin/food/dish/effort_level/dish_effort_levels'
    expect(response.status).to eq(200)
  end
  it 'treats a literal bracket dictionary source as an invalid regexp' do
    NormalizeWord.create!(entered_source: '[', entered_destination: 'x', source: '[', destination: 'x')
    expect { Business::Food::Dish::Word::Usecase::Normalizer.call(string_sequence: '[') }.to raise_error(RegexpError)
  end
end
