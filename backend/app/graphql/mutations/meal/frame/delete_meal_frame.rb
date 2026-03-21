module Mutations::Meal::Frame
  class DeleteMealFrame < ::Mutations::BaseMutation
    argument :id, Int, required: true

    field :meal_frame_id, Int, null: false

    def resolve(id:)
      ActiveRecord::Base.transaction do
        removed_frame_id = ::Business::Food::Meal::Frame::Usecase::RemoveCommand.call(
          user_id: context[:current_user_id],
          meal_frame_id: id,
        )
        { meal_frame_id: removed_frame_id }
      end
    end
  end
end
