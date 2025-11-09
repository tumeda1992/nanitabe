module Business::Food::Dish::Word
  class Usecase::AddCommand < ::Business::Base::Command
    attribute :source, :string
    validates :source, presence: true

    attribute :destination, :string
    validates :destination, presence: false

    def call
      normalized_source = Usecase::NormalizeCommand.call(
        string_sequence: source,
        use_db_normalize_word: false
      )
      normalized_destination = if destination.present?
                                 Usecase::NormalizeCommand.call(
                                   string_sequence: destination,
                                   use_db_normalize_word: false
                                 )
                               else
                                 normalized_source
                               end

      NormalizeWord.create(
        entered_source: source,
        entered_destination: destination.presence || "",
        source: normalized_source,
        destination: normalized_destination,
      )

      Usecase::ReflectLatestNormalizeWordCommand.call
    end
  end
end
