class DishSource < ApplicationRecord
  belongs_to :user
  self.inheritance_column = :_type_disabled

  validate :preserve_related_dish_details, on: :update, if: :will_save_change_to_type?

  scope :matching_normalized_name, ->(word) {
    where("dish_sources.name LIKE ?", "%#{word}%")
  }

  class << self
    def build_from_food_dish_source_root(food_dish_source_root)
      new(
        id: food_dish_source_root.id,
        user_id: food_dish_source_root.user_id,
        name: food_dish_source_root.name,
        type: food_dish_source_root.type.value,
        comment: food_dish_source_root.comment,
      )
    end
  end

  private

  def preserve_related_dish_details
    allowed = Business::Food::Dish::Source::Policy::TypeChangePolicy.allowed?(
      current_type: type_in_database,
      requested_type: type,
      has_related_dishes: DishSourceRelation.where(dish_source_id: id).exists?,
    )
    errors.add(:type, "料理が関連付けられているレシピ元の種別は変更できません。") unless allowed
  end
end
