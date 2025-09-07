class DishSourceRelation < ApplicationRecord
  self.primary_key = [:dish_id, :dish_source_id]
  belongs_to :dish
  belongs_to :dish_source

  def self.class_of(dish_source_type)
    source_type_prefix = ::Business::Dish::Dish::Source::Type
    case dish_source_type
    when source_type_prefix::YOUTUBE, source_type_prefix::WEBSITE
      SourceRelationOfWebsite
    when source_type_prefix::RECIPE_BOOK
      SourceRelationOfRecipeBook
    else
      SourceRelationOfOther
    end
  end

  class SourceRelationOfRecipeBook < self
    # これ以外は空確定で、この値だけ入ってきて未定義のこともあるよっていうバリデーション入れたいだけなのにうまく行かないからコメントアウト
    # validates :recipe_book_page, allow_nil: true
    validates :recipe_website_url, absence: true
    validates :recipe_source_memo, absence: true

    def set_detail(detail)
      self[:recipe_book_page] = detail[:recipe_book_page]
      self[:recipe_website_url] = nil
      self[:recipe_source_memo] = nil
    end

    def set_value(recipe_book_page)
      self[:recipe_book_page] = recipe_book_page
      self[:recipe_website_url] = nil
      self[:recipe_source_memo] = nil
    end
  end

  class SourceRelationOfWebsite < self
    validates :recipe_book_page, absence: true
    # validates :recipe_website_url, allow_nil: true
    validates :recipe_source_memo, absence: true

    def set_detail(detail)
      self[:recipe_book_page] = nil
      self[:recipe_website_url] = detail[:recipe_website_url]
      self[:recipe_source_memo] = nil
    end

    def set_value(recipe_website_url)
      self[:recipe_book_page] = nil
      self[:recipe_website_url] = recipe_website_url
      self[:recipe_source_memo] = nil
    end
  end

  class SourceRelationOfOther < self
    validates :recipe_book_page, absence: true
    validates :recipe_website_url, absence: true
    # validates :recipe_source_memo, allow_nil: true

    def set_detail(detail)
      self[:recipe_book_page] = nil
      self[:recipe_website_url] = nil
      self[:recipe_source_memo] = detail[:recipe_source_memo]
    end

    def set_value(recipe_source_memo)
      self[:recipe_book_page] = nil
      self[:recipe_website_url] = nil
      self[:recipe_source_memo] = recipe_source_memo
    end
  end
end
