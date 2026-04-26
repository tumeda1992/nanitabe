module Types::Input::Meal::Frame::Pattern
  class MealFramePatternEntryInput < Types::BaseInputObject
    argument :day_offset, Int, required: true
    argument :meal_type, Int, required: true
    argument :meal_frame_id, Int, required: true
  end
end
