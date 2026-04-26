module Mutations::Meal::Frame::Pattern
  class AddMealFramePattern < ::Mutations::BaseMutation
    argument :meal_frame_pattern, ::Types::Input::Meal::Frame::Pattern::MealFramePatternForCreate, required: true

    field :meal_frame_pattern_id, Int, null: false

    def resolve(meal_frame_pattern:)
      entries = meal_frame_pattern.entries.map do |entry|
        {
          day_offset: entry.day_offset,
          meal_type: entry.meal_type,
          meal_frame_id: entry.meal_frame_id,
        }
      end

      created_pattern = ::Business::Food::Meal::Frame::Pattern::Usecase::AddCommand.call(
        user_id: context[:current_user_id],
        name: meal_frame_pattern.name,
        entries:,
      )
      { meal_frame_pattern_id: created_pattern.id }
    end
  end
end
