module Business::Food::Dish
  module Usecase::Params
    class DishSourceRelation < ::Business::Base::CommandParams
      attribute :dish_source_id, :integer
      validates :dish_source_id, presence: false # 新規作成時には入っていないため

      attribute :relation_kind, :any # シンボルの入れ方がわからないため
      validates :relation_kind, presence: true
      attribute :relation_detail, :any
      validates :relation_detail, presence: true

      class << self
        def build_relation(dish_source_type, dish_source_id, detail_value)
          source_type_prefix = ::Business::Dish::Dish::Source::Type
          case dish_source_type
          when source_type_prefix::YOUTUBE, source_type_prefix::WEBSITE
            kind = :website
            detail = { url: detail_value }
          when source_type_prefix::RECIPE_BOOK
            kind = :book
            detail = { page: detail_value }
          else
            kind = :other
            detail = { memo: detail_value }
          end

          new(
            dish_source_id:,
            relation_kind: kind,
            relation_detail: detail,
          )
        end
      end

      def build_dish_source
        dish_source = ::Business::Food::Dish::Source::Factory.build_existing_from_id(dish_source_id)
        raise "指定したレシピ元は存在しません。" if dish_source.blank? # NOTE: このコマンド実行時に、新規sourceを紐つけるとしてもすでにsourceは作成済みの前提

        dish_source
      end

      def build_source_locator
        ::Business::Food::Dish::Source::Locator::Factory.build(relation_kind, **relation_detail)
      end

      def with_source_id(new_dish_source_id)
        self.class.new(
          dish_source_id: new_dish_source_id,
          relation_kind:,
          relation_detail:,
        )
      end
    end
  end
end
