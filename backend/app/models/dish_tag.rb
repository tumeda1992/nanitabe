class DishTag < ApplicationRecord
  belongs_to :dish
  belongs_to :user

  class << self
    def build_existing_roots_of_dish(dish_id)
      where(dish_id:).map do |tag_record|
        Business::Food::Dish::Tag::Root.new(
          id: tag_record.id,
          user_id: tag_record.user_id,
          content: Business::Food::Dish::Tag::Content.new(
            value: tag_record.content,
            normalized: tag_record.normalized_content
          )
        )
      end
    end

    def persist_from_root(root, dish_id)
      tag_record = if root.id.present?
                     find_by(id: root.id)
                   else
                     new(user_id: root.user_id, dish_id: dish_id)
                   end
      tag_record.persist_from_food_dish_root(root)

      tag_record
    end

    def replace_tags_of_dish(dish_id, tag_roots_for_replace)
      existing_records = where(dish_id:)

      tag_ids_for_replace = tag_roots_for_replace.map(&:id)
      existing_tag_ids = existing_records.map(&:id)

      return existing_records if tag_ids_for_replace == existing_tag_ids

      # 新規作成されたタグを追加
      tag_roots_for_replace.select { |tag| tag.id.blank? }.map do |tag_root|
        tag_record = persist_from_root(tag_root, dish_id)
        tag_root.set_id(tag_record.id)
        tag_root
      end

      # 既存タグで、置き換え対象に含まれないものを削除
      existing_tag_ids
        .reject { |existing_tag_id| tag_ids_for_replace.include?(existing_tag_id) }
        .map do |tag_id_needing_removed|
        ::DishTag.find_by(id: tag_id_needing_removed)&.destroy!
        tag_id_needing_removed
      end

      where(dish_id:)
    end
  end

  def persist_from_food_dish_root(root)
    self.content = root.content.value
    self.normalized_content = root.content.normalized

    save!
  end
end
