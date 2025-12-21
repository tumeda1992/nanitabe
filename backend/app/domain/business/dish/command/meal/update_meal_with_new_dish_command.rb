module Business::Dish
  module Command::Meal
    class UpdateMealWithNewDishCommand < ::Business::Base::Command
      attribute :user_id, :integer
      validates :user_id, presence: true

      attribute :dish_for_create, :command_params
      validates :dish_for_create, presence: true

      attribute :dish_source_for_read, :command_params
      validates :dish_source_for_read, presence: false

      attribute :dish_source_relation_detail, :command_params
      validates :dish_source_relation_detail, presence: false

      attribute :dish_tags, :command_params_array
      validates :dish_tags, presence: false

      attribute :meal_for_update, :command_params
      validates :meal_for_update, presence: true

      def call
        created_dish = ::Business::Dish::Dish::Command::AddCommand.call(
          user_id:,
          dish_for_create:,
          dish_source_for_read:,
          dish_source_relation_detail:,
          dish_tags:,
        )

        meal_for_update.dish_id = created_dish.id
        updated_meal = ::Business::Dish::Meal::Command::UpdateCommand.call(
          user_id:,
          meal_for_update:,
        )

        [updated_meal, created_dish]
      end
    end
  end
end
