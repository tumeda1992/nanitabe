module Business::Food::Dish
  class Name < ::Business::Base::ValueObject
    class DishNameForActiveModel < ActiveModel::Type::Value
      def cast_value(value)
        raise ArgumentError, "Invalid type" unless value.is_a?(Business::Food::Dish::Name) || value.nil?

        value
      end
    end

    attribute :value, :string
    validates :value, presence: true

    attribute :normalized, :string
    validates :normalized, presence: true

    class << self
      def initialize_and_normalize(value)
        normalized_value = ::Business::Food::Dish::Word::Usecase::Normalizer.call(string_sequence: value)
        new(value:, normalized: normalized_value)
      end
    end

    def initialize(attributes = {})
      super
    end
  end
end
