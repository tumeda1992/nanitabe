module Business::Food::Meal::Frame
  class Usecase::AddCommand < ::Business::Base::Command
    attribute :user_id, :integer
    validates :user_id, presence: true

    attribute :name, :string
    validates :name, presence: true

    def call
      frame_root = Business::Food::Meal::Frame::Root.new(
        user_id:,
        name:,
      )

      frame_record = ::MealFrame.persist_from_food_meal_frame_root(frame_root)
      frame_root.set_id(frame_record.id)

      frame_root
    end
  end
end
