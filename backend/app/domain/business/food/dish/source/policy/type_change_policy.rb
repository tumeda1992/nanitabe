module Business::Food::Dish::Source::Policy
  class TypeChangePolicy
    def self.allowed?(current_type:, requested_type:, has_related_dishes:)
      current_type == requested_type || !has_related_dishes
    end
  end
end
