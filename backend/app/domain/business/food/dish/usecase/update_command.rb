module Business::Food::Dish
  class Usecase::UpdateCommand < ::Business::Base::Command
    attribute :user_id, :integer
    validates :user_id, presence: true

    attribute :dish_params, :command_params
    validates :dish_params, presence: true
    validate :validate_dish, if: -> { dish_params.present? }

    def call
      dish_root = Business::Food::Dish::Factory.build_existing_from_id(dish_params.id)
      raise "指定した料理は存在しません。" if dish_root.blank?

      updated_dish_root = update_dish_root(dish_root, dish_params)

      # TODO: タグとの関連付け

      # TODO: ソースとの関連付け

      updated_dish_root
    end

    private

    def validate_dish
      return if dish_params.valid_for_update?

      errors.add(:dish_params, dish_params.errors.full_messages.join(', '))
    end

    def update_dish_root(dish_root, dish_params)
      dish_root.rename(dish_params.name) if dish_params.name.present?
      dish_root.reposition_in_meal(dish_params.meal_position) if dish_params.meal_position.present?
      dish_root.revise_comment(dish_params.comment) unless dish_params.comment.nil?

      dish_root.validate!

      dish_record = ::Dish.find(dish_root.id)
      update_attributes = {}
      update_attributes[:name] = dish_root.name if dish_params.name.present?
      update_attributes[:normalized_name] = dish_root.normalized_name if dish_params.name.present?
      update_attributes[:meal_position] = dish_root.meal_position if dish_params.meal_position.present?
      update_attributes[:comment] = dish_root.comment unless dish_params.comment.nil?

      dish_record.update!(update_attributes)

      dish_root
    end
  end
end
