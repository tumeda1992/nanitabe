require_relative "../../../../../support/factories/user_repository"
require_relative "../../../../../support/factories/dish_repository"
require_relative "../../../../../support/factories/dish_sources_repository"

KEY_OF_TEST_DISH_SOURCE_RELATION_SHOULD_BE_CREATED = "DISH_SOURCE_RELATION_SHOULD_BE_CREATED"
comparer = ExpectationComparer.new(KEY_OF_TEST_DISH_SOURCE_RELATION_SHOULD_BE_CREATED, {
  recipe_book_page: 32,
})

comparer.define_required_records_for_test do
  {
    user_record: find_or_create_user(),
    dish_record: find_or_create_dish(),
    dish_source_record: find_or_create_dish_source(),
  }
end

comparer.define_expectation do |expected_values, prepared_records|
  added_dish_source_relation_record = ::DishSourceRelation.find_by(
    dish_id: expected_values[:dish_id] || prepared_records[:dish_record].id,
    dish_source_id: expected_values[:dish_source_id] || prepared_records[:dish_source_record].id,
  )
  expect(added_dish_source_relation_record.recipe_book_page).to eq expected_values[:recipe_book_page]
  expect(added_dish_source_relation_record.recipe_website_url).to eq nil
  expect(added_dish_source_relation_record.recipe_source_memo).to eq nil
end

COMPARERS[comparer.key] = comparer

KEY_OF_TEST_DISH_SOURCE_RELATION_OF_YOUTUBE_SHOULD_BE_CREATED = "DISH_SOURCE_RELATION_OF_YOUTUBE_SHOULD_BE_CREATED"
comparer = ExpectationComparer.new(KEY_OF_TEST_DISH_SOURCE_RELATION_OF_YOUTUBE_SHOULD_BE_CREATED, {
  recipe_website_url: "https://youtube.com/ryuji/gyoza",
})

comparer.define_required_records_for_test do
  {
    user_record: find_or_create_user(),
    dish_record: find_or_create_dish(),
    dish_source_record: find_or_create_dish_source_of_youtube(),
  }
end

comparer.define_expectation do |expected_values, prepared_records|
  added_dish_source_relation_record = ::DishSourceRelation.find_by(
    dish_id: prepared_records[:dish_record].id,
    dish_source_id: prepared_records[:dish_source_record].id,
  )
  expect(added_dish_source_relation_record.recipe_book_page).to eq nil
  expect(added_dish_source_relation_record.recipe_website_url).to eq expected_values[:recipe_website_url]
  expect(added_dish_source_relation_record.recipe_source_memo).to eq nil
end

COMPARERS[comparer.key] = comparer

KEY_OF_TEST_DISH_SOURCE_RELATION_OF_OTHER_SHOULD_BE_CREATED = "DISH_SOURCE_RELATION_OF_OTHER_SHOULD_BE_CREATED"
comparer = ExpectationComparer.new(KEY_OF_TEST_DISH_SOURCE_RELATION_OF_OTHER_SHOULD_BE_CREATED, {
  recipe_source_memo: "駅最寄りの駐輪場を曲がったところ",
})

comparer.define_required_records_for_test do
  {
    user_record: find_or_create_user(),
    dish_record: find_or_create_dish(),
    dish_source_record: find_or_create_dish_source_of_other(),
  }
end

comparer.define_expectation do |expected_values, prepared_records|
  added_dish_source_relation_record = ::DishSourceRelation.find_by(
    dish_id: prepared_records[:dish_record].id,
    dish_source_id: prepared_records[:dish_source_record].id,
  )
  expect(added_dish_source_relation_record.recipe_book_page).to eq nil
  expect(added_dish_source_relation_record.recipe_website_url).to eq nil
  expect(added_dish_source_relation_record.recipe_source_memo).to eq expected_values[:recipe_source_memo]
end

COMPARERS[comparer.key] = comparer

KEY_OF_TEST_DISH_SOURCE_RELATION_OF_OTHER_WITHOUT_DETAIL_VALUE_SHOULD_BE_CREATED = "DISH_SOURCE_RELATION_OF_OTHER_WITHOUT_DETAIL_VALUE_SHOULD_BE_CREATED"
comparer = ExpectationComparer.new(KEY_OF_TEST_DISH_SOURCE_RELATION_OF_OTHER_WITHOUT_DETAIL_VALUE_SHOULD_BE_CREATED, {
  recipe_source_memo: "",
})

comparer.define_required_records_for_test do
  {
    user_record: find_or_create_user(),
    dish_record: find_or_create_dish(),
    dish_source_record: find_or_create_dish_source_of_other(),
  }
end

comparer.define_expectation do |expected_values, prepared_records|
  added_dish_source_relation_record = ::DishSourceRelation.find_by(
    dish_id: expected_values[:dish_id] || prepared_records[:dish_record].id,
    dish_source_id: expected_values[:dish_source_id] || prepared_records[:dish_source_record].id,
    )
  expect(added_dish_source_relation_record.recipe_book_page).to eq nil
  expect(added_dish_source_relation_record.recipe_website_url).to eq nil
  expect(added_dish_source_relation_record.recipe_source_memo).to eq nil
end

COMPARERS[comparer.key] = comparer

KEY_OF_TEST_DISH_SOURCE_RELATION_SHOULD_BE_UPDATED = "DISH_SOURCE_RELATION_SHOULD_BE_UPDATED"
comparer = ExpectationComparer.new(KEY_OF_TEST_DISH_SOURCE_RELATION_SHOULD_BE_UPDATED, {
  recipe_book_page: 150,
})

comparer.define_required_records_for_test do
  {
    user_record: find_or_create_user(),
    dish_record: find_or_create_dish(),
    dish_source_record: find_or_create_dish_source(),
    dish_source_relation_record: find_or_create_dish_source_relation(),
  }
end

comparer.define_expectation do |expected_values, prepared_records|
  updated_dish_source_relation_record = ::DishSourceRelation.find_by(
    dish_id: prepared_records[:dish_source_relation_record].dish_id,
    dish_source_id: expected_values[:dish_source_id].presence || prepared_records[:dish_source_relation_record].dish_source_id,
  )
  expect(updated_dish_source_relation_record.recipe_book_page).to eq expected_values[:recipe_book_page]
  expect(updated_dish_source_relation_record.recipe_website_url).to eq nil
  expect(updated_dish_source_relation_record.recipe_source_memo).to eq nil
end

COMPARERS[comparer.key] = comparer

KEY_OF_TEST_DISH_SOURCE_RELATION_SHOULD_BE_UPDATED_TO_DIFFERENT_SOURCE_TYPE_DETAIL = "DISH_SOURCE_RELATION_SHOULD_BE_UPDATED_TO_DIFFERENT_SOURCE_TYPE_DETAIL"
comparer = ExpectationComparer.new(KEY_OF_TEST_DISH_SOURCE_RELATION_SHOULD_BE_UPDATED_TO_DIFFERENT_SOURCE_TYPE_DETAIL, {
  recipe_website_url: "https://youtube.com/ryuji/gyoza",
})

comparer.define_required_records_for_test do
  {
    user_record: find_or_create_user(),
    dish_record: find_or_create_dish(),
    # 変化前レコード
    dish_source_record: find_or_create_dish_source(),
    dish_source_relation_record: find_or_create_dish_source_relation(),
  }
end

comparer.define_expectation do |expected_values, prepared_records|
  updated_dish_source_relation_record = ::DishSourceRelation.find_by(
    dish_id: prepared_records[:dish_source_relation_record].dish_id,
    dish_source_id: prepared_records[:dish_source_relation_record].dish_source_id,
  )
  expect(updated_dish_source_relation_record.recipe_book_page).to eq nil
  expect(updated_dish_source_relation_record.recipe_website_url).to eq expected_values[:recipe_website_url]
  expect(updated_dish_source_relation_record.recipe_source_memo).to eq nil
end

COMPARERS[comparer.key] = comparer

KEY_OF_TEST_DISH_SOURCE_RELATION_HAS_NO_UPDATE = "DISH_SOURCE_RELATION_HAS_NO_UPDATE"
comparer = ExpectationComparer.new(KEY_OF_TEST_DISH_SOURCE_RELATION_HAS_NO_UPDATE, {})

comparer.define_required_records_for_test do
  {
    user_record: find_or_create_user(),
    dish_record: find_or_create_dish(),
    dish_source_record: find_or_create_dish_source(),
    dish_source_relation_record: find_or_create_dish_source_relation(),
  }
end

comparer.define_expectation do |_, prepared_records|
  relation_of_before_update = prepared_records[:dish_source_relation_record]
  updated_dish_source_relation_record = ::DishSourceRelation.find_by(
    dish_id: relation_of_before_update.dish_id,
    dish_source_id: relation_of_before_update.dish_source_id,
  )
  expect(updated_dish_source_relation_record.recipe_book_page).to eq relation_of_before_update.recipe_book_page
  expect(updated_dish_source_relation_record.recipe_website_url).to eq nil
  expect(updated_dish_source_relation_record.recipe_source_memo).to eq nil
end

COMPARERS[comparer.key] = comparer
