module Business::Food::Dish::Tag
  class Content < ::Business::Base::ValueObject
    attribute :value, :string
    validates :value, presence: true

    attribute :normalized, :string
    validates :normalized, presence: true

    class << self
      def initialize_and_normalize(value)
        normalized_value = ::Business::Food::Dish::Word::Usecase::Normalizer.call(string_sequence: value)
        new(value:, normalized: normalized_value)
      end

      def initialize_with_normalizing_if_need(value, normalized)
        if normalized.blank?
          initialize_and_normalize(value)
        else
          new(value:, normalized:)
        end
      end
    end
  end
end
