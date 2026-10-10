module Mutations::Meal::Postponed
  class PostponeMeal < ::Mutations::BaseMutation
    argument :meal_id, Int, required: true

    field :postponed_meal_id, Int, null: false

    def resolve(meal_id:)
      ActiveRecord::Base.transaction do
        meal_record = ::Meal.find_by(id: meal_id, user_id: context[:current_user_id])
        raise "指定した食事は存在しません。" if meal_record.blank?

        postponed_meal_root = ::Business::Food::Meal::Postponed::Usecase::AddCommand.call(
          user_id: context[:current_user_id],
          dish_id: meal_record.dish_id,
          meal_type: meal_record.meal_type,
          comment: meal_record.comment,
        )

        ::Business::Food::Meal::Usecase::RemoveCommand.call(
          user_id: context[:current_user_id],
          meal_id: meal_record.id,
        )

        { postponed_meal_id: postponed_meal_root.id }
      end
    end
  end
end
