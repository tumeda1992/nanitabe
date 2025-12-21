DISH_NAME_OF_DISH ||= "かつ丼"

def find_or_create_dish
  ::Dish.find_by(name: DISH_NAME_OF_DISH) || FactoryBot.create(:dish)
end

DISH_NAME_OF_DISH_2 ||= "天丼"

def find_or_create_dish_2
  ::Dish.find_by(name: DISH_NAME_OF_DISH_2) || FactoryBot.create(:dish_2)
end

Object.class_eval do
  (1..6).each do |idx|
    multi_const_name = "DISH_NAME_OF_DAY_WITH_MULTI_MEALS_#{idx}"
    meal_const_name  = "DISH_NAME_OF_DAY_WITH_MEAL_#{idx}"

    const_set(multi_const_name, multi_const_name) unless const_defined?(multi_const_name)
    const_set(meal_const_name,  meal_const_name)  unless const_defined?(meal_const_name)

    define_method(:"find_or_create_dish_of_day_with_multi_meals_#{idx}") do
      ::Dish.find_by(name: Object.const_get(multi_const_name)) ||
        FactoryBot.create(:"dish_of_day_with_multi_meals_#{idx}")
    end

    define_method(:"find_or_create_dish_of_day_with_meal_#{idx}") do
      ::Dish.find_by(name: Object.const_get(meal_const_name)) ||
        FactoryBot.create(:"dish_of_day_with_meal_#{idx}")
    end
  end
end
