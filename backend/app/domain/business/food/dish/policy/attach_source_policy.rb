module Business::Food::Dish
  class Policy::AttachSourcePolicy
    class << self
      def ok?(source, source_locator)
        return true if source.nil? && source_locator.nil?
        return false if source.nil? || source_locator.nil?

        Business::Food::Dish::Source::Locator::LocatorCompatibility.supports?(source.type, source_locator.kind)
      end
    end
  end
end
