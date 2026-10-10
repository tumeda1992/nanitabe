module Business::Food::Meal::Postponed
  class Root < ::Business::Base::Entity
    attribute :id, :integer

    attribute :user_id, :integer
    validates :user_id, presence: true

    attribute :dish_id, :integer
    validates :dish_id, presence: true

    attribute :meal_type, :integer
    validates :meal_type, presence: true

    attribute :comment, :string
    validates :comment, presence: false

    def set_id(new_id)
      raise "新規作成時以外idを変更できません" if id.present?

      self.id = new_id
    end
  end
end
