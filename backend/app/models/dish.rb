class Dish < ApplicationRecord
  # ソート用デフォルト値（手間未設定の料理をソートする際に使用）
  EFFORT_DEFAULT_MINUTES_BY_MEAL_POSITION = {
    1 => 20,  # 主食
    2 => 20,  # メインディッシュ
    3 => 10,  # 副菜
  }.freeze

  validates :name, presence: true
  validates :meal_position, presence: true

  belongs_to :user
  has_many :meals

  has_one :dish_source_relation, dependent: :destroy
  has_one :dish_source, through: :dish_source_relation

  has_one :dish_evaluation, dependent: :destroy
  has_many :dish_tags, dependent: :destroy

  belongs_to :dish_effort_level, optional: true

  scope :for_user, ->(user_id) { where(user_id: user_id) }

  scope :with_search_relations, -> {
    # サブクエリで食事登録回数を計算（GROUP BYを避けるため）
    meals_count_subquery = Meal.select("dish_id, COUNT(*) as meals_count")
                               .group("dish_id")
    last_cooked_date_subquery = Meal.select("dish_id, MAX(date) as last_cooked_date")
                                    .group("dish_id")
    joins("LEFT JOIN (#{meals_count_subquery.to_sql}) AS meal_counts ON meal_counts.dish_id = dishes.id")
      .joins("LEFT JOIN (#{last_cooked_date_subquery.to_sql}) AS meal_last_dates ON meal_last_dates.dish_id = dishes.id")
      .left_joins(:dish_source, :dish_source_relation, :dish_evaluation, :dish_tags, :dish_effort_level) # has_manyは重複するけど、あとでdistinctするので問題ない
      .preload(:dish_source, :dish_source_relation, :dish_evaluation, :dish_tags)
  }

  scope :search_output, -> {
    select_clauses = []
    select_clauses.push("dishes.*")
    select_clauses.push("dish_sources.name AS dish_source_name")
    select_clauses.push("dish_evaluations.score AS evaluation_score")
    select_clauses.push("COALESCE(dish_evaluations.score, 3.0 - 0.01) AS evaluation_score_for_sort")
    select_clauses.push("COALESCE(meal_counts.meals_count, 0) AS meals_count")
    select_clauses.push("dish_effort_levels.minutes AS effort_level_minutes")
    select_clauses.push("meal_last_dates.last_cooked_date AS last_cooked_date")

    order_clauses = []
    order_clauses.push("evaluation_score_for_sort DESC")
    order_clauses.push("meals_count DESC")
    order_clauses.push("dishes.created_at DESC")

    select(select_clauses.join(", "))
      .distinct
      .order(Arel.sql(order_clauses.join(", ")))
  }

  scope :matching_normalized_name, ->(word) {
    where("COALESCE(dishes.normalized_name, dishes.name) LIKE ?", "%#{word}%")
  }

  # 食事登録の有無で絞り込み
  # registered: true -> 食事に登録されている料理のみ
  # registered: false -> 食事に登録されていない料理のみ
  # registered: nil -> フィルタリングしない（全て）
  # 注意: with_search_relations スコープと一緒に使う必要がある（meal_counts.meals_count を使用）
  scope :by_meal_registration, ->(registered = nil) {
    return all if registered.nil?

    if registered
      where("COALESCE(meal_counts.meals_count, 0) > 0")
    else
      where("COALESCE(meal_counts.meals_count, 0) = 0")
    end
  }

  class << self
    def build_existing_root_from_id(id)
      dish_record = find_by(id: id)
      return if dish_record.blank?

      source_locator = build_source_locator_from_relation(dish_record)

      ::Business::Food::Dish::Root.new(
        id: dish_record.id,
        user_id: dish_record.user_id,
        name: ::Business::Food::Dish::Name.new(
          value: dish_record.name,
          normalized: dish_record.normalized_name,
        ),
        meal_position: dish_record.meal_position,
        comment: dish_record.comment,
        source_id: dish_record.dish_source&.id,
        source_locator: source_locator,
        tags: ::DishTag.build_existing_roots_of_dish(dish_record.id),
        effort_level_id: dish_record.dish_effort_level_id,
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
        ::Business::Food::Dish::Source::Locator::RecipeBook.new(relation.recipe_book_page)
      when ::Business::Food::Dish::Source::Type::YOUTUBE, ::Business::Food::Dish::Source::Type::WEBSITE
        ::Business::Food::Dish::Source::Locator::RecipeWebsite.new(relation.recipe_website_url)
      else
        ::Business::Food::Dish::Source::Locator::OtherRecipe.new(relation.recipe_source_memo)
      end
    end
  end

  def persist_from_food_dish_root(food_dish_root)
    self.name = food_dish_root.name.value
    self.normalized_name = food_dish_root.name.normalized
    self.meal_position = food_dish_root.meal_position
    self.comment = food_dish_root.comment
    self.dish_effort_level_id = food_dish_root.effort_level_id
    save!

    if food_dish_root.source_id.present?
      ::DishSourceRelation.put_dish_source_relation(id, food_dish_root.source_id, food_dish_root.source_locator)
    else
      ::DishSourceRelation.remove_dish_source_relation(id)
    end

    ::DishTag.replace_tags_of_dish(id, food_dish_root.tags)

    self
  end

  def to_searched_values
    result = attributes

    dish_relation = if dish_source_relation.present? && dish_source.present?
                      {
                        dish_id: dish_source_relation.dish_id,
                        type: dish_source.type,
                        source_name: dish_source.name,
                        dish_source_id: dish_source.id,
                        recipe_book_page: dish_source_relation.recipe_book_page,
                        recipe_website_url: dish_source_relation.recipe_website_url,
                        recipe_source_memo: dish_source_relation.recipe_source_memo,
                      }
                    end
    result[:dish_source_relation] = dish_relation
    result[:evaluation_score] = dish_evaluation&.score
    result[:tags] = (dish_tags.presence || []).map(&:attributes)

    result.with_indifferent_access
  end
end
