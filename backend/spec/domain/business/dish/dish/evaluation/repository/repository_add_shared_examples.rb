require_relative "../../../../../../support/factories/user_repository"
require_relative "../../../../../../support/factories/dish_repository"

KEY_OF_TEST_DISH_EVALUATION_SHOULD_BE_CREATED = "DISH_EVALUATION_SHOULD_BE_CREATED"
comparer = ExpectationComparer.new(KEY_OF_TEST_DISH_EVALUATION_SHOULD_BE_CREATED, {
  score: 3.5,
})

comparer.define_required_records_for_test do
  {
    user_record: find_or_create_user(),
    dish_record: find_or_create_dish(),
  }
end

comparer.define_expectation do |expected_values, prepared_records|
  added_dish_evaluation_record = ::DishEvaluation.last
  expect(added_dish_evaluation_record.user_id).to eq prepared_records[:user_record].id
  expect(added_dish_evaluation_record.dish_id).to eq prepared_records[:dish_record].id
  expect(added_dish_evaluation_record.score).to eq expected_values[:score]
end

COMPARERS[comparer.key] = comparer
