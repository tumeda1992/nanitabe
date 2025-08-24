module Business::Food::Dish
  module Usecase::Params
    class Detail < ::Business::Base::CommandParams
      def detail_values
        attributes.select do |k, _|
          [:dish_id, :dish_source_id].exclude?(k.to_sym)
        end.map { |(k, v)| [k.to_sym, v] }.to_h
      end

      def kind
        raise NotImplementedError
      end
    end

    class RelationDetailOfUrl < Detail
      DETAIL_VALUE_FIELD_NAME = :recipe_website_url
      attribute :recipe_website_url, :string
      def kind = :website
    end

    class RelationDetailOfPage < Detail
      DETAIL_VALUE_FIELD_NAME = :recipe_book_page
      attribute :recipe_book_page, :integer
      def kind = :book
    end

    class RelationDetailOfMemo < Detail
      DETAIL_VALUE_FIELD_NAME = :recipe_source_memo
      attribute :recipe_source_memo, :string
      def kind = :other
    end

    class Relation < ::Business::Base::CommandParams
      attribute :dish_id, :integer
      validates :dish_id, presence: true
      attribute :dish_source_id, :integer
      validates :dish_source_id, presence: true
      attribute :relation_detail, :command_params
      validates :relation_detail, presence: true
    end

    class DishSourceRelation
      class << self
        def build_relation(dish_source_type, dish_id, dish_source_id, detail_value)
          Relation.new(
            dish_id:,
            dish_source_id:,
            relation_detail: build_relation_detail(dish_source_type, detail_value),
          )
        end

        def build_relation_detail(dish_source_type, detail_value)
          source_type_prefix = ::Business::Dish::Dish::Source::Type
          detail_class = case dish_source_type
                         when source_type_prefix::YOUTUBE, source_type_prefix::WEBSITE
                           RelationDetailOfUrl
                         when source_type_prefix::RECIPE_BOOK
                           RelationDetailOfPage
                         else
                           RelationDetailOfMemo
                         end
          detail_values = if detail_value.is_a?(Hash)
                            detail_value
                          else
                            { detail_class::DETAIL_VALUE_FIELD_NAME => detail_value }
                          end
          detail_class.new(**detail_values)
        end
      end
    end
  end
end
