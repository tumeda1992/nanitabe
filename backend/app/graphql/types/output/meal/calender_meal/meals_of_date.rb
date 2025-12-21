module Types::Output::Meal::CalenderMeal
  class MealsOfDate < ::Types::BaseObject
    field :date, GraphQL::Types::ISO8601Date, null: false
    field :meals, [MealForCalender, { null: false }], null: false
  end
end
