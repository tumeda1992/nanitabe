module Business::Food::Meal::Frame
  class Usecase::UpdateCommand < ::Business::Base::Command
    attribute :user_id, :integer
    validates :user_id, presence: true

    attribute :meal_frame_id, :integer
    validates :meal_frame_id, presence: true

    attribute :name, :string
    validates :name, presence: true

    def call
      frame_root = ::MealFrame.build_existing_root_from_id(meal_frame_id)
      frame_root.rename(name)

      ::MealFrame.persist_from_food_meal_frame_root(frame_root)

      frame_root
    end
  end
end
