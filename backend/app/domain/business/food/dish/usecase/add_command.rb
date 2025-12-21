module Business::Food::Dish
  class Usecase::AddCommand < ::Business::Base::Command
    attribute :user_id, :integer
    validates :user_id, presence: true

    attribute :dish_params, :command_params
    validates :dish_params, presence: true
    validate :validate_dish, if: -> { dish_params.present? }

    attribute :dish_source_relation, :command_params
    validates :dish_source_relation, presence: false

    # 型は Business::Food::Dish::Tag::Usecase::Params::Tag の配列
    attribute :dish_tags, :command_params_array, default: []
    validates :dish_tags, disallow_nil: true

    def call
      source = dish_source_relation.present? ? dish_source_relation.build_dish_source : nil
      source_locator = dish_source_relation.present? ? dish_source_relation.build_source_locator : nil

      dish_root = Business::Food::Dish::Factory.build(
        user_id,
        dish_params.name,
        dish_params.meal_position,
        comment: dish_params.comment,
        source:,
        source_locator:,
        tags: dish_tags.map {|tag| tag.to_root(user_id)},
      )

      dish_record = ::Dish.persist_from_food_dish_root(dish_root)
      dish_root.set_id(dish_record.id)

      dish_root
    end

    private

    def validate_dish
      return if dish_params.valid_for_create?

      errors.add(:dish_params, dish_params.errors.full_messages.join(", "))
    end
  end
end
