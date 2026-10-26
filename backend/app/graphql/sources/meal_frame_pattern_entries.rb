module Sources
  class MealFramePatternEntries < GraphQL::Dataloader::Source
    def fetch(pattern_ids)
      entries = ::MealFramePatternEntry.where(meal_frame_pattern_id: pattern_ids).group_by(&:meal_frame_pattern_id)
      pattern_ids.map { |id| entries.fetch(id, []) }
    end
  end
end
