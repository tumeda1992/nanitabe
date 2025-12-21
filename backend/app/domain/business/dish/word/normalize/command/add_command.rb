module Business::Dish::Word::Normalize
  class Command::AddCommand < ::Business::Base::Command
    attribute :source, :string
    validates :source, presence: true

    attribute :destination, :string
    validates :destination, presence: false

    # 一旦1つのテーブルのモデルしか使わないのでrepository.addとか使わずに運用。複雑性が増したら分離
    def call
      NormalizeWord.create(
        entered_source: source,
        entered_destination: destination,
        source: Command::NormalizeCommand.call(
          string_sequence: source,
          use_db_normalize_word: false,
        ),
        destination: Command::NormalizeCommand.call(
          string_sequence: destination,
          use_db_normalize_word: false,
        ),
      )
    end
  end
end
