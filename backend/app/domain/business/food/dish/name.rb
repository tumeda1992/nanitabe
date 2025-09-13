module Business::Food::Dish
  class Name < ::Business::Base::ValueObject
    attribute :value, :string
    validates :value, presence: true

    attribute :normalized, :string
    validates :normalized, presence: true

    class << self
      def initialize_and_normalize(value)
        normalized_value = ::Business::Dish::Word::Normalize::Command::NormalizeCommand.call(string_sequence: value)
        new(value:, normalized: normalized_value)
      end
    end

    def initialize(attributes = {})
      super
    end
  end
end
