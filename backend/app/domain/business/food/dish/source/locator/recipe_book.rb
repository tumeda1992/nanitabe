module Business::Food::Dish::Source
  class Locator::RecipeBook < Locator::Base
    attr_reader :page

    def initialize(page)
      super
      raise ArgumentError, "page must be a positive integer" unless page.to_i >= 1

      @page = page.to_i
    end

    def kind = :book

    def detail_value = page
  end
end
