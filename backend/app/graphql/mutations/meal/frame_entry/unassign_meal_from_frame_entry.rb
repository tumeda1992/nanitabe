module Mutations::Meal::FrameEntry
  class UnassignMealFromFrameEntry < ::Mutations::BaseMutation
    argument :frame_entry_id, Int, required: true

    field :frame_entry_id, Int, null: false

    def resolve(frame_entry_id:)
      ActiveRecord::Base.transaction do
        record = MealFrameEntry.find_by!(id: frame_entry_id, user_id: context[:current_user_id])
        root = ::Business::Food::Meal::Frame::Entry::Usecase::UnassignMealCommand.call(
          user_id: context[:current_user_id],
          meal_frame_entry_id: record.id,
        )
        { frame_entry_id: root.id }
      end
    end
  end
end
