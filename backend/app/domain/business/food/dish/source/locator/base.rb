module Business::Food::Dish::Source
  class Locator::Base
    def ==(other)
      other.class == self.class && other.detail_value == detail_value
    end

    def detail_value
      raise NotImplementedError
    end
  end
end
