module Mutations::Meal::Postponed
  class SchedulePostponedMeal < ::Mutations::BaseMutation
    argument :postponed_meal_id, Int, required: true
    argument :date, GraphQL::Types::ISO8601Date, required: true

    field :meal_id, Int, null: false

    def resolve(postponed_meal_id:, date:)
      ActiveRecord::Base.transaction do
        postponed_meal_record = ::PostponedMeal.find_by(
          id: postponed_meal_id,
          user_id: context[:current_user_id],
        )
        raise "指定した延期された食事は存在しません。" if postponed_meal_record.blank?

        meal_params = ::Business::Food::Meal::Usecase::Params::Meal.new(
          dish_id: postponed_meal_record.dish_id,
          date:,
          meal_type: postponed_meal_record.meal_type,
          comment: postponed_meal_record.comment,
        )
        created_meal = ::Business::Food::Meal::Usecase::AddCommand.call(
          user_id: context[:current_user_id],
          meal_params:,
        )

        ::Business::Food::Meal::Postponed::Usecase::RemoveCommand.call(
          user_id: context[:current_user_id],
          postponed_meal_id: postponed_meal_record.id,
        )

        { meal_id: created_meal.id }
      end
    end
  end
end
