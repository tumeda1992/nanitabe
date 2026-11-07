module Sources
  class MealFramePatternEntries < GraphQL::Dataloader::Source
    def initialize(user_id)
      super()
      @user_id = user_id
    end

    def fetch(pattern_ids)
      relation = ::MealFramePatternEntry.where(meal_frame_pattern_id: pattern_ids)
                                        .joins(:meal_frame_pattern)
                                        .left_joins(:meal_frame)
                                        .where(meal_frame_patterns: { user_id: @user_id })
      entries = relation.where(meal_frames: { user_id: @user_id })
                        .or(relation.where(meal_frames: { id: nil }))
                        .group_by(&:meal_frame_pattern_id)
      pattern_ids.map { |id| entries.fetch(id, []) }
    end
  end
end
