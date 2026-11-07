module Business::Food::Meal::Frame
  class Usecase::RemoveCommand < ::Business::Base::Command
    attribute :user_id, :integer
    validates :user_id, presence: true

    attribute :meal_frame_id, :integer
    validates :meal_frame_id, presence: true

    def call
      frame_record = ::MealFrame.where(user_id: user_id).find(meal_frame_id)

      if ::MealFrameEntry.exists?(meal_frame_id:)
        raise "枠にエントリが登録されているため削除できません。"
      end

      if ::MealFramePatternEntry.exists?(meal_frame_id:)
        raise "パターンのエントリに使用されているため削除できません。"
      end

      frame_record.destroy!

      meal_frame_id
    end
  end
end
