module Mutations::Dish::Word
  class AddWord < ::Mutations::BaseMutation
    argument :word, ::Types::Input::Dish::Word::WordForCreate, required: true

    field :normalize_word_id, Int, null: false

    def resolve(word:)
      ActiveRecord::Base.transaction do
        created_word = ::Business::Food::Dish::Word::Usecase::AddCommand.call(
          source: word[:source],
          destination: word[:destination],
        )

        {
          normalize_word_id: created_word.id,
        }
      end
    end
  end
end
