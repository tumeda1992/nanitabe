module Business::Food::Dish::Word
  module Usecase::NormalizeWordAttributes
    def self.build(source:, destination:)
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

      {
        entered_source: source,
        entered_destination: destination.presence || "",
        source: normalized_source,
        destination: normalized_destination,
      }
    end
  end
end
