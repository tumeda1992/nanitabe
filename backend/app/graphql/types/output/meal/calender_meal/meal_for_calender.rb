module Types::Output::Meal::CalenderMeal
  class MealForCalender < ::Types::BaseObject
    implements ::Types::Output::Meal::MealFields

    field :meal_frame_entry_id, Integer, null: true
    field :meal_frame_name, String, null: true
  end
end
