module Business::Food::Meal
  class Usecase::AddCommand < ::Business::Base::Command
    attribute :user_id, :integer
    validates :user_id, presence: true

    attribute :meal_params, :command_params
    validates :meal_params, presence: true
    validate :validate_meal, if: -> { meal_params.present? }

    def call
      meal_root = Business::Food::Meal::Factory.build(
        user_id,
        meal_params.dish_id,
        meal_params.date,
        meal_params.meal_type,
        comment: meal_params.comment
      )

      meal_record = ::Meal.persist_from_food_meal_root(meal_root)
      meal_root.set_id(meal_record.id)

      meal_root
    end

    private

    def validate_meal
      return if meal_params.valid_for_create?

      errors.add(:meal_params, meal_params.errors.full_messages.join(', '))
    end
  end
end
