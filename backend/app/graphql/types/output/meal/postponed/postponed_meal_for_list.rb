module Types::Output::Meal::Postponed
  class PostponedMealForList < Types::BaseObject
    field :id, Int, null: false
    field :dish_id, Int, null: false
    field :dish_name, String, null: false
    field :meal_type, Int, null: false
    field :comment, String, null: true
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
  end
end
