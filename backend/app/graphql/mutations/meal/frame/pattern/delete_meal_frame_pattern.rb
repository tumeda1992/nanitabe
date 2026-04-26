module Mutations::Meal::Frame::Pattern
  class DeleteMealFramePattern < ::Mutations::BaseMutation
    argument :id, Int, required: true

    field :meal_frame_pattern_id, Int, null: false

    def resolve(id:)
      deleted_id = ::Business::Food::Meal::Frame::Pattern::Usecase::RemoveCommand.call(
        meal_frame_pattern_id: id,
      )
      { meal_frame_pattern_id: deleted_id }
    end
  end
end
