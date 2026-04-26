module Mutations::Meal::Frame::Pattern
  class UpdateMealFramePattern < ::Mutations::BaseMutation
    argument :meal_frame_pattern, ::Types::Input::Meal::Frame::Pattern::MealFramePatternForUpdate, required: true

    field :meal_frame_pattern_id, Int, null: false

    def resolve(meal_frame_pattern:)
      entries = meal_frame_pattern.entries.map do |entry|
        {
          day_offset: entry.day_offset,
          meal_type: entry.meal_type,
          meal_frame_id: entry.meal_frame_id,
        }
      end

      updated_pattern = ::Business::Food::Meal::Frame::Pattern::Usecase::UpdateCommand.call(
        meal_frame_pattern_id: meal_frame_pattern.id,
        name: meal_frame_pattern.name,
        entries:,
      )
      { meal_frame_pattern_id: updated_pattern.id }
    end
  end
end
