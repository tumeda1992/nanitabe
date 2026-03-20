module Queries::Dish
  class ExistingDishForRegisteringWithMeal < ::Types::BaseObject
    implements ::Types::Output::Dish::DishFields

    field :dish_source_name, String, null: true
    field :effort_level_minutes, Int, null: true
  end

  class ExistingDishesForRegisteringWithMeal < ::Queries::BaseQuery
    argument :dish_id_registered_with_meal, Int, required: false
    argument :search_string, String, required: false
    argument :meal_position, Int, required: false
    argument :registered_with_meal, Boolean, required: false

    type [ExistingDishForRegisteringWithMeal, { null: false }], null: false

    def resolve(search_string: nil, dish_id_registered_with_meal: nil, meal_position: nil, registered_with_meal: nil)
      ::Business::Food::Dish::Usecase::DishSearcher.call(
        access_user_id: context[:current_user_id],
        search_string:,
        dish_id_registered_with_meal:,
        meal_position:,
        registered_with_meal:,
      )
    end
  end
end
