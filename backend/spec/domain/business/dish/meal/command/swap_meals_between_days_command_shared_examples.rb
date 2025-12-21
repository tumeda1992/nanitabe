KEY_OF_TEST_SWAP_FROM_DAY_WITH_MEALS_TO_DAY_WITH_MEALS = "SWAP_FROM_DAY_WITH_MEALS_TO_DAY_WITH_MEALS"
comparer = ExpectationComparer.new(KEY_OF_TEST_SWAP_FROM_DAY_WITH_MEALS_TO_DAY_WITH_MEALS, {
  date1: Date.new(2023, 2, 1),
  date2: Date.new(2023, 2, 2),
})

comparer.define_required_records_for_test do
  {
    user_record: find_or_create_user,
    meal_of_day_1_with_multi_meals_1_record: find_or_create_meal_of_day_1_with_multi_meals_1,
    meal_of_day_1_with_multi_meals_2_record: find_or_create_meal_of_day_1_with_multi_meals_2,
    meal_of_day_2_with_multi_meals_1_record: find_or_create_meal_of_day_2_with_multi_meals_1,
    meal_of_day_2_with_multi_meals_2_record: find_or_create_meal_of_day_2_with_multi_meals_2,
    meal_of_day_2_with_multi_meals_3_record: find_or_create_meal_of_day_2_with_multi_meals_3,
  }
end

comparer.define_expectation do |expected_values, prepared_records|
  meal_ids_of_date1_after_exec = ::Meal.where(date: expected_values[:date1]).map(&:id)
  expected_meal_ids_of_date1_after_exec = [
    prepared_records[:meal_of_day_2_with_multi_meals_1_record].id,
    prepared_records[:meal_of_day_2_with_multi_meals_2_record].id,
    prepared_records[:meal_of_day_2_with_multi_meals_3_record].id,
  ]
  expect(meal_ids_of_date1_after_exec).to eq expected_meal_ids_of_date1_after_exec

  meal_ids_of_date2_after_exec = ::Meal.where(date: expected_values[:date2]).map(&:id)
  expected_meal_ids_of_date2_after_exec = [
    prepared_records[:meal_of_day_1_with_multi_meals_1_record].id,
    prepared_records[:meal_of_day_1_with_multi_meals_2_record].id,
  ]
  expect(meal_ids_of_date2_after_exec).to eq expected_meal_ids_of_date2_after_exec
end

COMPARERS[comparer.key] = comparer

KEY_OF_TEST_SWAP_FROM_DAY_WITH_MEAL_TO_DAY_WITHOUT_MEAL = "SWAP_FROM_DAY_WITH_MEAL_TO_DAY_WITHOUT_MEAL"
comparer = ExpectationComparer.new(KEY_OF_TEST_SWAP_FROM_DAY_WITH_MEAL_TO_DAY_WITHOUT_MEAL, {
  date1: Date.new(2023, 02, 11),
  date2: Date.new(2023, 02, 21),
})

comparer.define_required_records_for_test do
  {
    user_record: find_or_create_user,
    meal_of_day_1_with_meal_record: find_or_create_meal_of_day_1_with_meal,
  }
end

comparer.define_expectation do |expected_values, prepared_records|
  meal_ids_of_date1_after_exec = ::Meal.where(date: expected_values[:date1]).map(&:id)
  expected_meal_ids_of_date1_after_exec = []
  expect(meal_ids_of_date1_after_exec).to eq expected_meal_ids_of_date1_after_exec

  meal_ids_of_date2_after_exec = ::Meal.where(date: expected_values[:date2]).map(&:id)
  expected_meal_ids_of_date2_after_exec = [
    prepared_records[:meal_of_day_1_with_meal_record].id,
  ]
  expect(meal_ids_of_date2_after_exec).to eq expected_meal_ids_of_date2_after_exec
end

COMPARERS[comparer.key] = comparer

KEY_OF_TEST_SWAP_FROM_DAY_WITHOUT_MEAL_TO_DAY_WITH_MEAL = "SWAP_FROM_DAY_WITHOUT_MEAL_TO_DAY_WITH_MEAL"
comparer = ExpectationComparer.new(KEY_OF_TEST_SWAP_FROM_DAY_WITHOUT_MEAL_TO_DAY_WITH_MEAL, {
  date1: Date.new(2023, 02, 21),
  date2: Date.new(2023, 02, 11),
})

comparer.define_required_records_for_test do
  {
    user_record: find_or_create_user,
    meal_of_day_1_with_meal_record: find_or_create_meal_of_day_1_with_meal,
  }
end

comparer.define_expectation do |expected_values, prepared_records|
  meal_ids_of_date1_after_exec = ::Meal.where(date: expected_values[:date1]).map(&:id)
  expected_meal_ids_of_date1_after_exec = [
    prepared_records[:meal_of_day_1_with_meal_record].id,
  ]
  expect(meal_ids_of_date1_after_exec).to eq expected_meal_ids_of_date1_after_exec

  meal_ids_of_date2_after_exec = ::Meal.where(date: expected_values[:date2]).map(&:id)
  expected_meal_ids_of_date2_after_exec = []
  expect(meal_ids_of_date2_after_exec).to eq expected_meal_ids_of_date2_after_exec
end

COMPARERS[comparer.key] = comparer

KEY_OF_TEST_SWAP_FROM_DAY_WITHOUT_MEAL_TO_DAY_WITHOUT_MEAL = "SWAP_FROM_DAY_WITHOUT_MEAL_TO_DAY_WITHOUT_MEAL"
comparer = ExpectationComparer.new(KEY_OF_TEST_SWAP_FROM_DAY_WITHOUT_MEAL_TO_DAY_WITHOUT_MEAL, {
  date1: Date.new(2023, 02, 21),
  date2: Date.new(2023, 02, 22),
})

comparer.define_required_records_for_test do
  {
    user_record: find_or_create_user,
  }
end

comparer.define_expectation do |expected_values, _|
  meal_ids_of_date1_after_exec = ::Meal.where(date: expected_values[:date1]).map(&:id)
  expected_meal_ids_of_date1_after_exec = []
  expect(meal_ids_of_date1_after_exec).to eq expected_meal_ids_of_date1_after_exec

  meal_ids_of_date2_after_exec = ::Meal.where(date: expected_values[:date2]).map(&:id)
  expected_meal_ids_of_date2_after_exec = []
  expect(meal_ids_of_date2_after_exec).to eq expected_meal_ids_of_date2_after_exec
end

COMPARERS[comparer.key] = comparer
