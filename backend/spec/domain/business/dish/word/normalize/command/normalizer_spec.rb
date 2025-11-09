# frozen_string_literal: true

require "rails_helper"

module Business::Dish::Word::Normalize
  RSpec.describe Command::NormalizeCommand do
    describe ".call (without db)" do
      subject { described_class.call(string_sequence: target_string, use_db_normalize_word: false) }

      context "when there is hiragana, " do
        let(:target_string) { "ぶたにく" }
        it { is_expected.to eq "ブタニク" }
      end

      context "when there is zenkaku, " do
        let(:target_string) { "ＵＳＡ" }
        it { is_expected.to eq "USA" }
      end

      context "when there is zenkaku space, " do
        let(:target_string) { "豚肉　タレ" }
        it { is_expected.to eq "豚肉 タレ" }
      end
    end

    describe ".call" do
      subject { described_class.call(string_sequence: target_string) }

      context "when there is kana which can be kanji, " do
        let!(:normalize_word) { FactoryBot.create(:normalize_word_from_ambiguous_1) }
        let!(:normalize_word_2) { FactoryBot.create(:normalize_word_from_ambiguous_2) }
        let(:target_string) { "とり" }
        it { is_expected.to eq "鶏" }
      end
    end
  end
end
