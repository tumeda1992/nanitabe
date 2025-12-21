module Business::Dish::Dish::Tag
  class Repository < ::Business::Base::Repository
    class << self
      def fetch_tags_of_dish(dish_id)
        existing_tag_records = ::DishTag.where(dish_id:)
        existing_tag_records.map do |existing_tag_record|
          set_same_name_fields(existing_tag_record, DishTag.new, [:id, :user_id, :dish_id, :content, :normalized_content])
        end
      end

      def add(tag)
        new_dish_tag_record = set_same_name_fields(tag, ::DishTag.new, [:user_id, :dish_id, :content, :normalized_content])
        new_dish_tag_record.save!
        tag
      end

      def all_dish_tags
        ::DishTag.all.map do |dish_tag_record|
          # ::Dish.all.where("dishes.normalized_name IS NULL").map do |dish_record| # デバッグ
          build_values_object_with_existing_object(dish_tag_record, DishTag, [:id, :user_id, :dish_id, :content, :normalized_content])
        end
      end

      # コマンド未作成。正規化反映のために暫定的に作成
      def update(updated_dish_tag)
        existing_dish_tag_record = ::DishTag.find(updated_dish_tag.id)

        dish_tag_record_for_update = set_same_name_fields(updated_dish_tag, existing_dish_tag_record, [:user_id, :dish_id, :content, :normalized_content])
        dish_tag_record_for_update.save!
      end

      def remove(dish_tag_id, force_remove: false)
        existing_dish_tag_record = ::DishTag.find(dish_tag_id)
        existing_dish_tag_record.destroy!
      end
    end
  end
end
