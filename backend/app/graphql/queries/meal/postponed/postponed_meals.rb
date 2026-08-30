module Queries::Meal::Postponed
  class PostponedMeals < ::Queries::BaseQuery
    type [::Types::Output::Meal::Postponed::PostponedMealForList, { null: false }], null: false

    def resolve
      ::Business::Food::Meal::Postponed::Usecase::PostponedMealsFinder.call(
        user_id: context[:current_user_id],
      )
    end
  end
end
