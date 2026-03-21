module Queries::Meal::Frame
  class MealFrames < ::Queries::BaseQuery
    type [Types::Output::Meal::Frame::MealFrameForList, { null: false }], null: false

    def resolve
      ::Business::Food::Meal::Frame::Usecase::IndexFinder.call(
        user_id: context[:current_user_id],
      )
    end
  end
end
