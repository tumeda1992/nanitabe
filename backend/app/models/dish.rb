class Dish < ApplicationRecord
  validates :name, presence: true
  validates :meal_position, presence: true

  belongs_to :user
  has_many :meals

  has_one :dish_source_relation, dependent: :destroy
  has_one :dish_source, through: :dish_source_relation

  has_one :dish_evaluation, dependent: :destroy
  has_many :dish_tags, dependent: :destroy

  class << self
    def build_existing_root_from_id(id)
      dish_record = find_by(id: id)
      return if dish_record.blank?

      source_locator = build_source_locator_from_relation(dish_record)

      # NOTE: (マージ前に消す。docs配下のアーキテクチャのところに明記)
      # ActiveRecordがドメインモデルの集約を知っていて良いのか
      # →いい。本来Repositoryとしてドメインモデル内に作ろうとした存在だから
      ::Business::Food::Dish::Root.new(
        id: dish_record.id,
        user_id: dish_record.user_id,
        name: ::Business::Food::Dish::Name.new(
          value: dish_record.name,
          normalized: dish_record.normalized_name
        ),
        meal_position: dish_record.meal_position,
        comment: dish_record.comment,
        source_id: dish_record.dish_source&.id,
        source_locator: source_locator,
        tags: ::DishTag.build_existing_roots_of_dish(dish_record.id),
      )
    end

    def persist_from_food_dish_root(food_dish_root)
      dish_record = if food_dish_root.id.present?
                      find_by(id: food_dish_root.id)
                    else
                      new(user_id: food_dish_root.user_id)
                    end
      dish_record.persist_from_food_dish_root(food_dish_root)

      dish_record
    end

    private

    def build_source_locator_from_relation(dish_record)
      return nil unless dish_record.dish_source_relation

      relation = dish_record.dish_source_relation
      source_type = dish_record.dish_source&.type

      case source_type
      when ::Business::Food::Dish::Source::Type::RECIPE_BOOK
        return nil if relation.recipe_book_page.blank?
        ::Business::Food::Dish::Source::Locator::RecipeBook.new(relation.recipe_book_page)
      when ::Business::Food::Dish::Source::Type::YOUTUBE, ::Business::Food::Dish::Source::Type::WEBSITE
        return nil if relation.recipe_website_url.blank?
        ::Business::Food::Dish::Source::Locator::RecipeWebsite.new(relation.recipe_website_url)
      else
        ::Business::Food::Dish::Source::Locator::OtherRecipe.new(relation.recipe_source_memo)
      end
    end
  end

  # TODO: テスト作成。commandという使われ方に依存してはいけない
  def persist_from_food_dish_root(food_dish_root)
    self.name = food_dish_root.name.value
    self.normalized_name = food_dish_root.name.normalized
    self.meal_position = food_dish_root.meal_position
    self.comment = food_dish_root.comment
    save!

    if food_dish_root.source_id.present?
      ::DishSourceRelation.put_dish_source_relation(self.id, food_dish_root.source_id, food_dish_root.source_locator)
    else
      ::DishSourceRelation.remove_dish_source_relation(self.id)
    end

    ::DishTag.replace_tags_of_dish(self.id, food_dish_root.tags)

    self
  end
end
