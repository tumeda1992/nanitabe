module Queries::Meal
  class MealsForCalender < ::Queries::BaseQuery
    argument :start_date, GraphQL::Types::ISO8601Date, required: true
    argument :last_date, GraphQL::Types::ISO8601Date, required: true

    type [Types::Output::Meal::CalenderMeal::MealsOfDate, { null: false }], null: false

    def resolve(start_date:, last_date:)
      timer = ExecutionTimer.new(execution_name: "resolve query of MealsForCalender")

      hoge = ::Business::Food::Meal::Usecase::DateMealsFinder.call(
        access_user_id: context[:current_user_id],
        start_date:,
        last_date:,
      )

      timer.log_elapsed_time
      hoge
    end
  end
end
