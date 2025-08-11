module Business::Food::Dish
  class Usecase::AddCommand < ::Business::Base::Command
    attribute :user_id, :integer
    validates :user_id, presence: true

    attribute :dish_params, :command_params
    validates :dish_params, presence: true
    validate :validate_dish, if: -> { dish_params.present? }

    def call
      dish_root = Business::Food::Dish::Factory.build(
        user_id,
        dish_params.name,
        dish_params.meal_position,
        comment: dish_params.comment
      )
      dish_record = ::Dish.build_from_food_dish_root(dish_root)
      dish_record.save!

      # TODO: タグとの関連付け

      # TODO: ソースとの関連付け

      dish_root
    end

    private

    def validate_dish
      return if dish_params.valid_for_create?

      errors.add(:dish_params, dish_params.errors.full_messages.join(', '))
    end
  end
end
