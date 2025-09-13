require_relative "./user_repository"
require_relative "./dish_repository"

FactoryBot.define do
  factory :dish do
    user { find_or_create_user() }
    name { DISH_NAME_OF_DISH }
    normalized_name { DISH_NAME_OF_DISH }
    meal_position { 1 }
  end

  factory :dish_2, class: Dish do
    user { find_or_create_user() }
    name { DISH_NAME_OF_DISH_2 }
    normalized_name { DISH_NAME_OF_DISH_2 }
    meal_position { 2 }
  end

  (1..6).each do |idx|
    eval <<-DISH_OF_DAY_WITH_MEAL
      factory :dish_of_day_with_multi_meals_#{idx}, class: Dish do
        user { find_or_create_user() }
        name { DISH_NAME_OF_DAY_WITH_MULTI_MEALS_#{idx} }
        meal_position { 2 }
      end

      factory :dish_of_day_with_meal_#{idx}, class: Dish do
        user { find_or_create_user() }
        name { DISH_NAME_OF_DAY_WITH_MEAL_#{idx} }
        meal_position { 2 }
      end
    DISH_OF_DAY_WITH_MEAL
  end
end
