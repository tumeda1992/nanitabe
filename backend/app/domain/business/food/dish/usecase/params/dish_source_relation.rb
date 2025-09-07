module Business::Food::Dish
  module Usecase::Params
    class DishSourceRelation < ::Business::Base::CommandParams
      attribute :dish_id, :integer
      validates :dish_id, presence: true
      attribute :dish_source_id, :integer
      validates :dish_source_id, presence: true

      attribute :relation_kind, :any # シンボルの入れ方がわからないため
      validates :relation_kind, presence: true
      attribute :relation_detail, :any
      validates :relation_detail, presence: true

      class << self
        def build_relation(dish_source_type, dish_id, dish_source_id, detail_value)
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
            dish_id:,
            dish_source_id:,
            relation_kind: kind,
            relation_detail: detail,
          )
        end
      end
    end
  end
end
