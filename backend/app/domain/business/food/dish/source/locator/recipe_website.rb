module Business::Food::Dish::Source
  class Locator::RecipeWebsite < Locator::Base
    attr_reader :url

    def initialize(url)
      @url = url.present? ? coerce_url(url) : nil
    end

    def kind = :website
    # def to_h = { url: }
    def to_h = { recipe_website_url: url}
    # def detail_for_dish_source_relation_class = { recipe_website_url: url }

    def detail_value = url

    private

    def coerce_url(raw_url)
      uri = URI.parse(raw_url)
      raise ArgumentError, "Invalid URL" unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)

      uri.to_s
    rescue URI::InvalidURIError
      raise ArgumentError, "invalid url"
    end
  end
end
