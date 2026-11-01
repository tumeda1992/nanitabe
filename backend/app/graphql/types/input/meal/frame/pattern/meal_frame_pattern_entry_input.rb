module Types::Input::Meal::Frame::Pattern
  class MealFramePatternEntryInput < Types::BaseInputObject
    argument :day_offset, Int, required: true
    argument :meal_type, Int, required: true
    argument :meal_frame_id, Int, required: true

    def to_command_params
      {
        day_offset:,
        meal_type:,
        meal_frame_id:,
      }
    end
  end
end
