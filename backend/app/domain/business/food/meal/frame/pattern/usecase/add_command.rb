module Business::Food::Meal::Frame::Pattern
  class Usecase::AddCommand < ::Business::Base::Command
    attribute :user_id, :integer
    validates :user_id, presence: true

    attribute :name, :string
    validates :name, presence: true

    attribute :entries, default: -> { [] }

    def call
      pattern_root = Business::Food::Meal::Frame::Pattern::Root.new(
        user_id:,
        name:,
      )

      ActiveRecord::Base.transaction do
        pattern_record = ::MealFramePattern.persist_from_food_meal_frame_pattern_root(pattern_root)
        pattern_root.set_id(pattern_record.id)

        entries.each do |entry|
          Business::Food::Meal::Frame::Pattern::Entry::Usecase::AddCommand.call(
            meal_frame_pattern_id: pattern_root.id,
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
