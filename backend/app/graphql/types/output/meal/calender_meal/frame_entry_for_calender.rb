module Types::Output::Meal::CalenderMeal
  class FrameEntryForCalender < ::Types::BaseObject
    field :id, Integer, null: false
    field :meal_frame_id, Integer, null: false
    field :meal_frame_name, String, null: false
    field :meal_type, Integer, null: false
  end
end
