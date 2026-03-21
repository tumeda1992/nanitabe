module Types::Output::Meal::CalenderMeal
  class MealsOfDate < ::Types::BaseObject
    field :date, GraphQL::Types::ISO8601Date, null: false
    field :meals, [MealForCalender, { null: false }], null: false
    field :frame_entries, [FrameEntryForCalender, { null: false }], null: false
  end
end
