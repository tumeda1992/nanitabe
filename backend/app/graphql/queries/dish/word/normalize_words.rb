module Queries::Dish::Word
  class NormalizeWords < ::Queries::BaseQuery
    type [::Types::Output::Dish::Word::NormalizeWord, { null: false }], null: false

    def resolve
      ::NormalizeWord.all
    end
  end
end
