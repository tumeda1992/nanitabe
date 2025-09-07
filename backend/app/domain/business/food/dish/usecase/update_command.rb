module Business::Food::Dish
  class Usecase::UpdateCommand < ::Business::Base::Command
    attribute :user_id, :integer
    validates :user_id, presence: true

    attribute :dish_params, :command_params
    validates :dish_params, presence: true
    validate :validate_dish, if: -> { dish_params.present? }

    attribute :dish_source_relation, :command_params
    validates :dish_source_relation, presence: false

    def call
      dish_root = Business::Food::Dish::Factory.build_existing_from_id(dish_params.id)
      raise "指定した料理は存在しません。" if dish_root.blank?

      updated_dish_root = update_dish_root(dish_root, dish_params, dish_source_relation)

      ::Dish.persist_from_food_dish_root(dish_root)

      updated_dish_root
    end

    private

    def validate_dish
      return if dish_params.valid_for_update?

      errors.add(:dish_params, dish_params.errors.full_messages.join(', '))
    end

    def update_dish_root(dish_root, dish_params, dish_source_relation)
      dish_root.rename(dish_params.name) if dish_params.name.present?
      dish_root.reposition_in_meal(dish_params.meal_position) if dish_params.meal_position.present?
      dish_root.revise_comment(dish_params.comment) unless dish_params.comment.nil?

      # TODO: タグとの関連付け

      # TODO: ソースとの関連付け
      dish_root = update_dish_source_of_dish_root(dish_root, dish_source_relation)

      dish_root.validate!
      dish_root
    end

    def update_dish_source_of_dish_root(dish_root, dish_source_relation)
      # TODO: 「dishすでに登録済みのsourceの関連付けを外す」の対応の際にコメントアウト解除
      # if dish_source_relation.blank?
      #   return dish_root if dish_root.source_id.blank?
      #
      #   dish_root.detach_source
      #   return dish_root
      # end

      if dish_source_relation.present?
        dish_source = ::Business::Food::Dish::Source::Factory.build_existing_from_id(dish_source_relation.dish_source_id)
        raise "指定したレシピ元は存在しません。" if dish_source.blank? # NOTE: このコマンド実行時に、新規sourceを紐つけるとしてもすでにsourceは作成済みの前提

        source_locator = ::Business::Food::Dish::Source::Locator::Factory.build(dish_source_relation.relation_kind, **dish_source_relation.relation_detail)

        dish_root.attach_source(dish_source, source_locator)
      end

      dish_root
    end
  end
end
