module Business::Food::Dish::Source
  class Locator::RecipeWebsite < Locator::Base
    attr_reader :url

    def initialize(url)
      @url = coerce_url(url)
    end

    def kind = :website
    def to_h = { url: }

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
