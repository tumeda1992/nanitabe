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

      normalized_source = Usecase::Normalizer.call(
        string_sequence: source,
        use_db_normalize_word: false,
      )
      normalized_destination = if destination.present?
                                 Usecase::Normalizer.call(
                                   string_sequence: destination,
                                   use_db_normalize_word: false,
                                 )
                               else
                                 normalized_source
                               end

      existing_normalize_word.update!(
        entered_source: source,
        entered_destination: destination.presence || "",
        source: normalized_source,
        destination: normalized_destination,
      )

      Usecase::ReflectLatestNormalizeWordCommand.call
    end
  end
end
