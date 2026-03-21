module Mutations::Meal::FrameEntry
  class RemoveMealFrameEntry < ::Mutations::BaseMutation
    argument :id, Int, required: true

    field :meal_frame_entry_id, Int, null: false

    def resolve(id:)
      ActiveRecord::Base.transaction do
        removed_entry_id = ::Business::Food::Meal::FrameEntry::Usecase::RemoveCommand.call(
          user_id: context[:current_user_id],
          meal_frame_entry_id: id,
        )
        { meal_frame_entry_id: removed_entry_id }
      end
    end
  end
end
