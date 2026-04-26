module Queries::Meal::Frame::Pattern
  class MealFramePatterns < ::Queries::BaseQuery
    type [Types::Output::Meal::Frame::Pattern::MealFramePatternForList, { null: false }], null: false

    def resolve
      ::MealFramePattern.where(user_id: context[:current_user_id]).map do |record|
        {
          id: record.id,
          name: record.name,
        }
      end
    end
  end
end
