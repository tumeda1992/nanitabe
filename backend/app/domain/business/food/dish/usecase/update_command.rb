module Business::Food::Dish
  class Usecase::UpdateCommand < ::Business::Base::Command
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
      dish_root = Business::Food::Dish::Factory.build_existing_from_id(dish_params.id)
      raise "指定した料理は存在しません。" if dish_root.blank?

      updated_dish_root = update_dish_root(dish_root, dish_params, dish_source_relation, dish_tags)

      ::Dish.persist_from_food_dish_root(dish_root)

      updated_dish_root
    end

    private

    def validate_dish
      return if dish_params.valid_for_update?

      errors.add(:dish_params, dish_params.errors.full_messages.join(', '))
    end

    def update_dish_root(dish_root, dish_params, dish_source_relation, dish_tags)
      dish_root.rename(dish_params.name) if dish_params.name.present?
      dish_root.reposition_in_meal(dish_params.meal_position) if dish_params.meal_position.present?
      dish_root.revise_comment(dish_params.comment) unless dish_params.comment.nil?

      dish_root.replace_tags(dish_tags.map {|tag| tag.to_root(user_id)})

      dish_root = update_dish_source_of_dish_root(dish_root, dish_source_relation)

      dish_root.validate!
      dish_root
    end

    def update_dish_source_of_dish_root(dish_root, dish_source_relation)
      if dish_source_relation.blank?
        return dish_root if dish_root.source_id.blank?

        dish_root.detach_source
        return dish_root
      end

      dish_root.attach_source(dish_source_relation.build_dish_source, dish_source_relation.build_source_locator)
      dish_root
    end
  end
end
