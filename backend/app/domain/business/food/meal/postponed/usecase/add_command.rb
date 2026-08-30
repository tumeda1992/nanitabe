module Business::Food::Meal::Postponed
  class Usecase::AddCommand < ::Business::Base::Command
    attribute :user_id, :integer
    validates :user_id, presence: true

    attribute :dish_id, :integer
    validates :dish_id, presence: true

    attribute :meal_type, :integer
    validates :meal_type, presence: true

    attribute :comment, :string

    def call
      postponed_meal_root = Business::Food::Meal::Postponed::Factory.build(
        user_id,
        dish_id,
        meal_type,
        comment:,
      )

      postponed_meal_record = ::PostponedMeal.persist_from_food_meal_postponed_root(postponed_meal_root)
      postponed_meal_root.set_id(postponed_meal_record.id)

      postponed_meal_root
    end
  end
end
