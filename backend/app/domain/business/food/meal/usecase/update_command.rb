module Business::Food::Meal
  class Usecase::UpdateCommand < ::Business::Base::Command
    attribute :user_id, :integer
    validates :user_id, presence: true

    attribute :meal_params, :command_params
    validates :meal_params, presence: true
    validate :validate_meal, if: -> { meal_params.present? }

    def call
      meal_root = Business::Food::Meal::Factory.build_existing_from_id(meal_params.id)
      raise "指定した食事は存在しません。" if meal_root.blank?

      updated_dish_root = update_meal_root(meal_root, meal_params)

      ::Meal.persist_from_food_meal_root(updated_dish_root)

      updated_dish_root
    end

    private

    def validate_meal
      return if meal_params.valid_for_update?

      errors.add(:meal_params, meal_params.errors.full_messages.join(", "))
    end

    def update_meal_root(meal_root, meal_params)
      meal_root.assign_dish(meal_params.dish_id) if meal_params.dish_id.present?
      meal_root.reschedule(meal_params.date) if meal_params.date.present?
      meal_root.switch_meal_type(meal_params.meal_type) if meal_params.meal_type.present?
      meal_root.revise_comment(meal_params.comment) unless meal_params.comment.nil?

      meal_root.validate!
      meal_root
    end

  end
end
