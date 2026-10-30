module Business::Food::Dish::Word
  class Usecase::AddCommand < ::Business::Base::Command
    attribute :source, :string
    validates :source, presence: true

    attribute :destination, :string
    validates :destination, presence: false

    def call
      normalize_word = NormalizeWord.create(Usecase::NormalizeWordAttributes.build(source:, destination:))

      Usecase::ReflectLatestNormalizeWordCommand.call

      normalize_word
    end
  end
end
