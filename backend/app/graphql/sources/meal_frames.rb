module Sources
  class MealFrames < GraphQL::Dataloader::Source
    def initialize(user_id)
      super()
      @user_id = user_id
    end

    def fetch(frame_ids)
      frames = ::MealFrame.where(id: frame_ids, user_id: @user_id).index_by(&:id)
      frame_ids.map { |id| frames[id] }
    end
  end
end
