module Business::Food::Meal::Frame::Entry
  class Policy::AssignMealPolicy
    def self.ensure_available!(meal_id:, frame_entry_id:)
      return unless ::MealFrameEntry.where(meal_id: meal_id).where.not(id: frame_entry_id).exists?

      raise "この食事は既に別の枠に割り当てられています。"
    end
  end
end
