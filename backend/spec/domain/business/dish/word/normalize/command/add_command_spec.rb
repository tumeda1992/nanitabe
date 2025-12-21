# frozen_string_literal: true

require "rails_helper"

module Business::Dish::Word::Normalize
  RSpec.describe Command::AddCommand do
    describe ".call" do
      context "when add, " do
        it "adding succeeds" do
          described_class.call(
            source: "とり",
            destination: "鶏",
          )

          added_nomalize_word_record = ::NormalizeWord.last
          expect(added_nomalize_word_record.entered_source).to eq "とり"
          expect(added_nomalize_word_record.entered_destination).to eq "鶏"
          expect(added_nomalize_word_record.source).to eq "トリ"
          expect(added_nomalize_word_record.destination).to eq "鶏"
        end
      end
    end
  end
end
