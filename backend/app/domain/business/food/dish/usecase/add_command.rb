module Business::Food::Dish
  class Usecase::AddCommand < ::Business::Base::Command
    attribute :user_id, :integer
    validates :user_id, presence: true

    attribute :dish_param, :command_params
    validates :dish_param, presence: true
    validate :validate_dish, if: -> { dish_param.present? }

    def call
      dish_root = Business::Food::Dish::Factory.build(
        user_id,
        dish_param.name,
        dish_param.meal_position,
        comment: dish_param.comment
      )
      dish_record = ::Dish.build_from_food_dish_root(dish_root)
      dish_record.save!

      # TODO: タグとの関連付け

      # TODO: ソースとの関連付け

      dish_root
    end

    def validate_dish
      return if dish_param.valid?(on: :create)

      errors.add(:dish_param, dish_param.errors.full_messages.join(', '))
    end
  end
end
