module Business::Food::Dish
  class Policy::AttachSourcePolicy
    class << self
      def ensure!(source, source_locator)
        return true if source.nil? && source_locator.nil?
        raise "料理へのレシピ元関連付けにおいて、レシピ元が指定されていません" if source.nil?
        raise "料理へのレシピ元関連付けにおいて、レシピ元へのLocatorが指定されていません" if source_locator.nil?

        unless Business::Food::Dish::Source::Locator::LocatorCompatibility.supports?(source.type, source_locator.kind)
          raise "料理へのレシピ元関連付けにおいて、レシピ元に対して、Locatorの指定が誤っています (locator_kind: #{source_locator.kind}, source_type: #{source.type.value})"
        end

        true
      end
    end
  end
end
