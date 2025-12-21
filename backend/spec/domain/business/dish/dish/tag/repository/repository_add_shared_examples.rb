require_relative "../../../../../../support/factories/user_repository"
require_relative "../../../../../../support/factories/dish_repository"

KEY_OF_TEST_DISH_TAG_SHOULD_BE_CREATED = "DISH_TAG_SHOULD_BE_CREATED"
comparer = ExpectationComparer.new(KEY_OF_TEST_DISH_TAG_SHOULD_BE_CREATED, {
  content: "白ワインに合う",
  normalized_content: "白ワインニ合ウ",
})

comparer.define_required_records_for_test do
  {
    user_record: find_or_create_user(),
    dish_record: find_or_create_dish(),
  }
end

comparer.define_expectation do |expected_values, prepared_records|
  added_dish_tag_record = ::DishTag.last
  expect(added_dish_tag_record.user_id).to eq prepared_records[:user_record].id
  expect(added_dish_tag_record.dish_id).to eq expected_values[:dish_id] || prepared_records[:dish_record].id
  expect(added_dish_tag_record.content).to eq expected_values[:content]
  expect(added_dish_tag_record.normalized_content).to eq expected_values[:normalized_content]
end

COMPARERS[comparer.key] = comparer
