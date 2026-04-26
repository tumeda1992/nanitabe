module Mutations::Meal::Frame::Pattern
  class ApplyMealFramePattern < ::Mutations::BaseMutation
    argument :pattern_id, Int, required: true
    argument :start_date, String, required: true

    field :applied_meal_frame_pattern_id, Int, null: false

    def resolve(pattern_id:, start_date:)
      pattern = ::MealFramePattern.find_by(id: pattern_id)

      if pattern.nil? || pattern.user_id != context[:current_user_id]
        raise GraphQL::ExecutionError, "パターンが見つからないか、アクセス権がありません。"
      end

      parsed_start_date = Date.parse(start_date)
      entries = ::MealFramePatternEntry.where(meal_frame_pattern_id: pattern_id)

      ActiveRecord::Base.transaction do
        entries.each do |entry|
          date = parsed_start_date + (entry.day_offset - 1).days
          ::Business::Food::Meal::Frame::Entry::Usecase::AddCommand.call(
            user_id: context[:current_user_id],
            meal_frame_id: entry.meal_frame_id,
            date:,
            meal_type: entry.meal_type,
          )
        end
      end

      { applied_meal_frame_pattern_id: pattern_id }
    end
  end
end
