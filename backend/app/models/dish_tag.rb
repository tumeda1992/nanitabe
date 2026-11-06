class DishTag < ApplicationRecord
  belongs_to :dish
  belongs_to :user

  scope :matching_normalized_content, ->(word) {
    where("COALESCE(dish_tags.normalized_content, dish_tags.content) LIKE ?", "%#{word}%")
  }

  class << self
    def build_existing_roots_of_dish(dish_id)
      where(dish_id:).map do |tag_record|
        Business::Food::Dish::Tag::Root.new(
          id: tag_record.id,
          user_id: tag_record.user_id,
          content: Business::Food::Dish::Tag::Content.new(
            value: tag_record.content,
            normalized: tag_record.normalized_content,
          ),
        )
      end
    end

    def persist_from_root(root, dish_id)
      ::Dish.where(user_id: root.user_id).find(dish_id)
      tag_record = if root.id.present?
                     where(dish_id: dish_id, user_id: root.user_id).find(root.id)
                   else
                     new(user_id: root.user_id, dish_id: dish_id)
                   end
      tag_record.persist_from_food_dish_root(root)

      tag_record
    end

    def replace_tags_of_dish(dish_id, tag_roots_for_replace)
      transaction do
        dish = ::Dish.find(dish_id) if tag_roots_for_replace.any?
        existing_records = where(dish_id:).to_a
        owned_ids = existing_records.select { |tag| tag.user_id == dish&.user_id }.map(&:id)

        # 全入力の所属を先に検証し、不正IDで途中まで置き換えない。
        tag_roots_for_replace.each do |tag_root|
          tag_root.validate!
          unless tag_root.user_id == dish.user_id && (tag_root.id.blank? || owned_ids.include?(tag_root.id))
            raise ActiveRecord::RecordNotFound, "指定した料理のタグは存在しません。"
          end
        end

        tag_ids_for_replace = tag_roots_for_replace.map(&:id)
        tag_roots_for_replace.each do |tag_root|
          tag_record = persist_from_root(tag_root, dish_id)
          tag_root.set_id(tag_record.id) if tag_root.id.blank?
        end

        existing_records.reject { |tag| tag_ids_for_replace.include?(tag.id) }.each(&:destroy!)
        where(dish_id:)
      end
    end
  end

  def persist_from_food_dish_root(root)
    self.content = root.content.value
    self.normalized_content = root.content.normalized

    save!
  end
end
