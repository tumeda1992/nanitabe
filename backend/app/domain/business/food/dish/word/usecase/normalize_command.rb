module Business::Food::Dish::Word
  class Usecase::NormalizeCommand < ::Business::Base::Command
    attribute :string_sequence, :string
    validates :string_sequence, presence: true

    attribute :use_db_normalize_word, :boolean, default: true

    def call
      normalized = string_sequence.dup
      normalized.tr!("ぁ-ん","ァ-ン")
      normalized.tr!("０-９ａ-ｚＡ-Ｚ","0-9a-zA-Z")
      normalized.tr!("　"," ")

      return normalized unless use_db_normalize_word

      normalize_with_db_word(normalized)
    end

    private

    def normalize_with_db_word(string_sequence_arg)
      normalize_words = if Rails.env.test? # SQLite固有の記法
                          NormalizeWord.where("? LIKE '%' || normalize_words.source || '%'", string_sequence_arg)
                        else
                          NormalizeWord.where("? LIKE CONCAT('%', normalize_words.source, '%')", string_sequence_arg)
                        end
      normalize_words.reduce(string_sequence_arg.dup) do |normalized, normalize_word|
        # Rails.logger.info "★[正規化]対象:#{normalized} from:#{normalize_word.source} to:#{normalize_word.destination}" # デバッグ
        normalized.gsub(/#{normalize_word.source}/, normalize_word.destination)
      end
    end
  end
end
