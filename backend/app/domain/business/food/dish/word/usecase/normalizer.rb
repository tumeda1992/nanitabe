module Business::Food::Dish::Word
  class Usecase::Normalizer < ::Business::Base::Command
    attribute :string_sequence, :string
    validates :string_sequence, presence: true

    attribute :use_db_normalize_word, :boolean, default: true

    def call
      normalized = string_sequence.dup
      normalized.tr!("ぁ-ん", "ァ-ン")
      normalized.tr!("０-９ａ-ｚＡ-Ｚ", "0-9a-zA-Z")
      normalized.tr!("　", " ")

      return normalized unless use_db_normalize_word

      normalize_with_db_word(normalized)
    end

    private

    def normalize_with_db_word(string_sequence_arg)
      normalize_words = NormalizeWord.all.select { |word| string_sequence_arg.include?(word.source) }
      normalize_words.reduce(string_sequence_arg.dup) do |normalized, normalize_word|
        normalized.gsub(normalize_word.source) { normalize_word.destination }
      end
    end
  end
end
