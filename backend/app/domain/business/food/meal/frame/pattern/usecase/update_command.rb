module Business::Food::Meal::Frame::Pattern
  class Usecase::UpdateCommand < ::Business::Base::Command
    attribute :meal_frame_pattern_id, :integer
    validates :meal_frame_pattern_id, presence: true

    attribute :name, :string
    validates :name, presence: true

    attribute :entries, default: -> { [] }

    def call
      pattern_root = ::MealFramePattern.build_existing_root_from_id(meal_frame_pattern_id)
      pattern_root.rename(name)

      ActiveRecord::Base.transaction do
        ::MealFramePattern.persist_from_food_meal_frame_pattern_root(pattern_root)

        Business::Food::Meal::Frame::Pattern::Entry::Usecase::RemoveAllByPatternCommand.call(
          meal_frame_pattern_id:,
        )

        entries.each do |entry|
          Business::Food::Meal::Frame::Pattern::Entry::Usecase::AddCommand.call(
            meal_frame_pattern_id:,
            day_offset: entry[:day_offset],
            meal_type: entry[:meal_type],
            meal_frame_id: entry[:meal_frame_id],
          )
        end
      end

      pattern_root
    end
  end
end
