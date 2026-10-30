require 'securerandom'
ActiveRecord::Base.transaction do
  u = User.create!(id_param: SecureRandom.uuid)
  d = Dish.create!(user_id: u.id, name: 'plain', normalized_name: 'plain', meal_position: 1)
  a = DishTag.create!(user_id: u.id, dish_id: d.id, content: 'alpha', normalized_content: 'alpha')
  b = DishTag.create!(user_id: u.id, dish_id: d.id, content: 'beta', normalized_content: 'beta')
  result = Business::Food::Dish::Usecase::DishSearcher.call(access_user_id: u.id, search_string: 'alpha beta')
  puts "SEARCH_BOTH_TAGS=#{result.map { |x| x[:id] }.include?(d.id)}"
  tags = DishTag.build_existing_roots_of_dish(d.id)
  tags.first.content = Business::Food::Dish::Tag::Content.new(value: 'changed', normalized: 'changed')
  DishTag.replace_tags_of_dish(d.id, tags)
  puts "UPDATED_TAG=#{a.reload.content}"
  source = DishSource.create!(user_id: u.id, name: 'source', type: 1)
  DishSourceRelation.create!(dish_id: d.id, dish_source_id: source.id, recipe_book_page: 42)
  Business::Food::Dish::Source::Usecase::UpdateCommand.call(user_id: u.id, source_params: Business::Food::Dish::Source::Usecase::Params::Source.new(id: source.id, type: 3))
  root = Dish.build_existing_root_from_id(d.id)
  puts "SOURCE_LOCATOR=#{root.source_locator.detail_value.inspect}; STORED_PAGE=#{d.reload.dish_source_relation.recipe_book_page}"
  raise ActiveRecord::Rollback
end
