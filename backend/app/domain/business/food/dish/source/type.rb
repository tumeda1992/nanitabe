# config/initializers/types.rb のActiveModelのタイプ定義ファイルで読めるようにネスト形式に
module Business
  module Food
    module Dish
      module Source
        class Type < ::Business::Base::ValueObject
          RECIPE_BOOK = 1
          YOUTUBE = 2
          WEBSITE = 3
          RESTAURANT = 4
          OTHER = 50
          TYPES = [
            RECIPE_BOOK,
            YOUTUBE,
            WEBSITE,
            RESTAURANT,
            OTHER
          ]

          class DishSourceTypeForActiveModel < ActiveModel::Type::Value
            def cast_value(value)
              Type.new(value)
            end
          end

          class << self
            def recipe_book
              new(RECIPE_BOOK)
            end

            def youtube
              new(YOUTUBE)
            end

            def website
              new(WEBSITE)
            end

            def restaurant
              new(RESTAURANT)
            end

            def other
              new(OTHER)
            end
          end

          def initialize(type)
            raise ArgumentError, "Invalid type" unless TYPES.include?(type)

            @value = type
          end

          def value
            @value
          end
        end
      end
    end
  end
end
