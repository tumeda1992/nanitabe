module Mutations::Meal::Frame
  class UpdateMealFrame < ::Mutations::BaseMutation
    argument :meal_frame, ::Types::Input::Meal::Frame::MealFrameForUpdate, required: true

    field :meal_frame_id, Int, null: false

    def resolve(meal_frame:)
      ActiveRecord::Base.transaction do
        updated_frame = ::Business::Food::Meal::Frame::Usecase::UpdateCommand.call(
          user_id: context[:current_user_id],
          meal_frame_id: meal_frame.id,
          name: meal_frame.name,
        )
        { meal_frame_id: updated_frame.id }
      end
    end
  end
end
