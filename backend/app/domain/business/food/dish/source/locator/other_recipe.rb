module Business::Food::Dish::Source
  class Locator::OtherRecipe < Locator::Base
    attr_reader :memo

    def initialize(memo)
      @memo = memo
    end

    def kind = :other

    def detail_value = memo
  end
end
