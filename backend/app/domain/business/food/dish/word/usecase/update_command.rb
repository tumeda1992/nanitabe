module Business::Food::Dish::Word
  class Usecase::UpdateCommand < ::Business::Base::Command
    attribute :normalize_word_id, :integer
    validates :normalize_word_id, presence: true

    attribute :source, :string
    validates :source, presence: true

    attribute :destination, :string
    validates :destination, presence: false

    def call
      existing_normalize_word = NormalizeWord.find(normalize_word_id)

      existing_normalize_word.update!(Usecase::NormalizeWordAttributes.build(source:, destination:))

      Usecase::ReflectLatestNormalizeWordCommand.call
    end
  end
end
