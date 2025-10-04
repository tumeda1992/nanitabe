module Mutations::Meal
  class RemoveMeal < ::Mutations::BaseMutation
    argument :meal_id, Int, required: true

    field :meal_id, Int, null: false

    def resolve(meal_id:)
      ActiveRecord::Base.transaction do
        ::Business::Food::Meal::Usecase::RemoveCommand.call(
          meal_id:,
          user_id: context[:current_user_id],
        )
        { meal_id: }
      end
    end
  end
end
