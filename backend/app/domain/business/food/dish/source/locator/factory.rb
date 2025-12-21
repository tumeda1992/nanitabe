module Business::Food::Dish::Source
  class Locator::Factory
    class << self
      def build(kind, page: nil, url: nil, memo: nil)
        raise ArgumentError, "Unknown locator kind: #{kind}" if kind.nil?

        case kind.to_sym
        when :book
          Locator::RecipeBook.new(page)
        when :website
          Locator::RecipeWebsite.new(url)
        when :other
          Locator::OtherRecipe.new(memo)
        else
          raise ArgumentError, "Unknown locator kind: #{kind}"
        end
      end
    end
  end
end
