module Mutations::Meal::FrameEntry
  class AddMealFrameEntry < ::Mutations::BaseMutation
    argument :meal_frame_entry, ::Types::Input::Meal::FrameEntry::MealFrameEntryForCreate, required: true

    field :meal_frame_entry_id, Int, null: false

    def resolve(meal_frame_entry:)
      ActiveRecord::Base.transaction do
        created_entry = ::Business::Food::Meal::FrameEntry::Usecase::AddCommand.call(
          user_id: context[:current_user_id],
          meal_frame_id: meal_frame_entry.meal_frame_id,
          date: meal_frame_entry.date,
          meal_type: meal_frame_entry.meal_type,
        )
        { meal_frame_entry_id: created_entry.id }
      end
    end
  end
end
