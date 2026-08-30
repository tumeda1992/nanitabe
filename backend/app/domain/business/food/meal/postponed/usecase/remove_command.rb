module Business::Food::Meal::Postponed
  class Usecase::RemoveCommand < ::Business::Base::Command
    attribute :user_id, :integer
    validates :user_id, presence: true

    attribute :postponed_meal_id, :integer
    validates :postponed_meal_id, presence: true

    def call
      postponed_meal_record = ::PostponedMeal.find_by(id: postponed_meal_id)
      raise "指定した延期された食事は存在しません。" if postponed_meal_record.blank?

      postponed_meal_record.destroy!
    end
  end
end
