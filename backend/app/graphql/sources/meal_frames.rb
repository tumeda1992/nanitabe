module Sources
  class MealFrames < GraphQL::Dataloader::Source
    def fetch(frame_ids)
      frames = ::MealFrame.where(id: frame_ids).index_by(&:id)
      frame_ids.map { |id| frames[id] }
    end
  end
end
