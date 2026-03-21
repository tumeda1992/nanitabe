module Mutations::Meal::Frame
  class AddMealFrame < ::Mutations::BaseMutation
    argument :meal_frame, ::Types::Input::Meal::Frame::MealFrameForCreate, required: true

    field :meal_frame_id, Int, null: false

    def resolve(meal_frame:)
      ActiveRecord::Base.transaction do
        created_frame = ::Business::Food::Meal::Frame::Usecase::AddCommand.call(
          user_id: context[:current_user_id],
          name: meal_frame.name,
        )
        { meal_frame_id: created_frame.id }
      end
    end
  end
end
