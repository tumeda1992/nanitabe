module Mutations::Meal::FrameEntry
  class FillMealFrameEntry < ::Mutations::BaseMutation
    argument :frame_entry_id, Int, required: true
    argument :meal_id, Int, required: true

    field :frame_entry_id, Int, null: false

    def resolve(frame_entry_id:, meal_id:)
      ActiveRecord::Base.transaction do
        MealFrameEntry.find_by!(id: frame_entry_id, user_id: context[:current_user_id])
        root = ::Business::Food::Meal::Frame::Entry::Usecase::FillWithMealCommand.call(
          user_id: context[:current_user_id],
          meal_frame_entry_id: frame_entry_id,
          meal_id: meal_id,
        )
        { frame_entry_id: root.id }
      end
    end
  end
end
