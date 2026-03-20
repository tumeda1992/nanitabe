module Queries::Dish::EffortLevel
  class DishEffortLevels < ::Queries::BaseQuery
    type [Types::Output::Dish::EffortLevel::DishEffortLevel, { null: false }], null: false

    argument :meal_position, Int, required: true

    def resolve(meal_position:)
      ::DishEffortLevel.for_meal_position(meal_position)
    end
  end
end
