module Business::Food::Meal
  class Root < ::Business::Base::Entity
    attribute :id, :integer

    attribute :user_id, :integer
    validates :user_id, presence: true

    attribute :dish_id, :integer
    validates :dish_id, presence: true

    attribute :date, :date
    validates :date, presence: true

    attribute :meal_type, :integer
    validates :meal_type, presence: true

    attribute :comment, :string
    validates :comment, presence: false

    def set_id(new_id)
      raise "新規作成時以外idを変更できません" if self.id.present?

      self.id = new_id
    end

    def assign_dish(new_dish_id)
      Policy::AttachDishPolicy.ensure!(new_dish_id)

      self.dish_id = new_dish_id
    end

    def reschedule(new_date)
      raise "日付は空にできません。" if new_date.blank?

      self.date = new_date
    end

    def switch_meal_type(new_meal_type)
      raise "食事の種類は空にできません。" if new_meal_type.blank?

      self.meal_type = new_meal_type
    end

    def revise_comment(new_comment)
      self.comment = new_comment
    end
  end
end
