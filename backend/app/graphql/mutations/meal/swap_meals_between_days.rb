module Mutations::Meal
  class SwapMealsBetweenDays < ::Mutations::BaseMutation
    argument :date1, GraphQL::Types::ISO8601Date, required: true
    argument :date2, GraphQL::Types::ISO8601Date, required: true

    field :updated_meal_ids, [Int], null: true

    def resolve(date1:, date2:)
      ActiveRecord::Base.transaction do
        updated_meals = ::Business::Food::Meal::Usecase::SwapMealsBetweenDaysCommand.call(
          user_id: context[:current_user_id],
          date1:,
          date2:,
        )
        { updated_meal_ids: updated_meals.map(&:id) }
      end
    end
  end
end
