module Business::Food::Meal::Frame::Entry
  class Root < ::Business::Base::Entity
    attribute :id, :integer

    attribute :user_id, :integer
    validates :user_id, presence: true

    attribute :meal_frame_id, :integer
    validates :meal_frame_id, presence: true

    attribute :date, :date
    validates :date, presence: true

    attribute :meal_type, :integer
    validates :meal_type, presence: true

    attribute :meal_id, :integer

    def assign_meal(meal_id)
      self.meal_id = meal_id
    end

    def unassign_meal
      self.meal_id = nil
    end

    def set_id(new_id)
      raise "新規作成時以外idを変更できません" if id.present?

      self.id = new_id
    end
  end
end
