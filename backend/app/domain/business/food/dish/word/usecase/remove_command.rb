module Business::Food::Dish::Word
  class Usecase::RemoveCommand < ::Business::Base::Command
    attribute :normalize_word_id, :integer

    def call
      NormalizeWord.find(normalize_word_id).destroy!

      Usecase::ReflectLatestNormalizeWordCommand.call
    end
  end
end
