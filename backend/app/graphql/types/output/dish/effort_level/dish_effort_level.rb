module Types::Output::Dish::EffortLevel
  class DishEffortLevel < ::Types::BaseObject
    field :id, Int, null: false
    field :meal_position, Int, null: false
    field :minutes, Int, null: false
    field :label, String, null: false
  end
end
