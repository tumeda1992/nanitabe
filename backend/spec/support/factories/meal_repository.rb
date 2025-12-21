require_relative "./user_repository"
require_relative "./dish_repository"

def find_or_create_meal
  existing_meal = ::Meal.find_by(
    dish: find_or_create_dish(),
  )
  existing_meal || FactoryBot.create(:meal)
end

def find_or_create_meal_of_day_1_with_multi_meals_1
  existing_meal = ::Meal.find_by(
    dish: find_or_create_dish_of_day_with_multi_meals_1(),
  )
  existing_meal || FactoryBot.create(:meal_of_day_1_with_multi_meals_1)
end

def find_or_create_meal_of_day_1_with_multi_meals_2
  existing_meal = ::Meal.find_by(
    dish: find_or_create_dish_of_day_with_multi_meals_2(),
  )
  existing_meal || FactoryBot.create(:meal_of_day_1_with_multi_meals_2)
end

def find_or_create_meal_of_day_2_with_multi_meals_1
  existing_meal = ::Meal.find_by(
    dish: find_or_create_dish_of_day_with_multi_meals_3(),
  )
  existing_meal || FactoryBot.create(:meal_of_day_2_with_multi_meals_1)
end

def find_or_create_meal_of_day_2_with_multi_meals_2
  existing_meal = ::Meal.find_by(
    dish: find_or_create_dish_of_day_with_multi_meals_4(),
  )
  existing_meal || FactoryBot.create(:meal_of_day_2_with_multi_meals_2)
end

def find_or_create_meal_of_day_2_with_multi_meals_3
  existing_meal = ::Meal.find_by(
    dish: find_or_create_dish_of_day_with_multi_meals_5(),
  )
  existing_meal || FactoryBot.create(:meal_of_day_2_with_multi_meals_3)
end

def find_or_create_meal_of_day_1_with_meal
  existing_meal = ::Meal.find_by(
    dish: find_or_create_dish_of_day_with_meal_1(),
  )
  existing_meal || FactoryBot.create(:meal_of_day_1_with_meal)
end

def find_or_create_meal_of_day_2_with_meal
  existing_meal = ::Meal.find_by(
    dish: find_or_create_dish_of_day_with_meal_2(),
  )
  existing_meal || FactoryBot.create(:meal_of_day_1_with_meal)
end
