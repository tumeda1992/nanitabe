module Business::Food::Meal::Frame::Pattern::Entry
  class Root < ::Business::Base::Entity
    attribute :id, :integer

    attribute :meal_frame_pattern_id, :integer
    validates :meal_frame_pattern_id, presence: true

    attribute :day_offset, :integer
    validates :day_offset, presence: true, numericality: { greater_than: 0 }

    attribute :meal_type, :integer
    validates :meal_type, presence: true

    attribute :meal_frame_id, :integer
    validates :meal_frame_id, presence: true

    def set_id(new_id)
      raise "新規作成時以外idを変更できません" if id.present?

      self.id = new_id
    end
  end
end
