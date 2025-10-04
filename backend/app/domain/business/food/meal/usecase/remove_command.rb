module Business::Food::Meal
  class Usecase::RemoveCommand < ::Business::Base::Command
    attribute :user_id, :integer
    validates :user_id, presence: true

    attribute :meal_id, :integer
    validates :meal_id, presence: true

    def call
      meal_record = ::Meal.find_by(id: meal_id)
      raise "指定した食事は存在しません。" if meal_record.blank?

      meal_record.destroy!
    end
  end
end
