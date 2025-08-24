module Business::Food::Dish::Source
  class Locator::Base
    def ==(other)
      other.class == self.class && other.to_h == to_h
    end

    def kind
      raise NotImplementedError
    end

    # ハッシュ化（DBのJSON列/メッセージ越境用）
    def to_h
      raise NotImplementedError
    end
  end
end
