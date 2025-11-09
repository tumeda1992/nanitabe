require "rails_helper"

RSpec.describe Business::Food::Dish::Word::Usecase::Normalizer do
  describe "validations" do
    context "when string_sequence is missing" do
      it "raises validation error" do
        expect {
          described_class.call
        }.to raise_error(/String sequence can't be blank/)
      end
    end

    context "when string_sequence is nil" do
      it "raises validation error" do
        expect {
          described_class.call(string_sequence: nil)
        }.to raise_error(/String sequence can't be blank/)
      end
    end

    context "when string_sequence is empty string" do
      it "raises validation error" do
        expect {
          described_class.call(string_sequence: "")
        }.to raise_error(/String sequence can't be blank/)
      end
    end
  end

  describe "#call" do
    context "with use_db_normalize_word = false" do
      it "converts hiragana to katakana" do
        result = described_class.call(
          string_sequence: "ひらがな",
          use_db_normalize_word: false
        )
        expect(result).to eq("ヒラガナ")
      end

      it "converts full-width alphanumeric to half-width" do
        result = described_class.call(
          string_sequence: "０１２ａｂｃＡＢＣ",
          use_db_normalize_word: false
        )
        expect(result).to eq("012abcABC")
      end

      it "converts full-width space to half-width space" do
        result = described_class.call(
          string_sequence: "ぜんかく　すぺーす",
          use_db_normalize_word: false
        )
        expect(result).to eq("ゼンカク スペース")
      end

      it "applies all normalizations together" do
        result = described_class.call(
          string_sequence: "ひらがな　１２３ａｂｃ",
          use_db_normalize_word: false
        )
        expect(result).to eq("ヒラガナ 123abc")
      end

      it "does not modify katakana" do
        result = described_class.call(
          string_sequence: "カタカナ",
          use_db_normalize_word: false
        )
        expect(result).to eq("カタカナ")
      end

      it "does not modify half-width alphanumeric" do
        result = described_class.call(
          string_sequence: "123abc",
          use_db_normalize_word: false
        )
        expect(result).to eq("123abc")
      end
    end

    context "with use_db_normalize_word = true (default)" do
      let!(:normalize_word_pork) do
        FactoryBot.create(:normalize_word_from_kana_to_kanji)
        # source: "ブタ", destination: "豚"
      end

      let!(:normalize_word_chicken1) do
        FactoryBot.create(:normalize_word_from_ambiguous_1)
        # source: "鳥", destination: "鶏"
      end

      let!(:normalize_word_chicken2) do
        FactoryBot.create(:normalize_word_from_ambiguous_2)
        # source: "トリ", destination: "鶏"
      end

      it "applies basic normalization and db word replacement" do
        result = described_class.call(
          string_sequence: "ぶたにく"
        )
        # "ぶたにく" -> "ブタニク" -> "豚ニク"
        expect(result).to eq("豚ニク")
      end

      it "replaces multiple occurrences of the same word" do
        result = described_class.call(
          string_sequence: "ぶたとぶた"
        )
        # "ぶたとぶた" -> "ブタトブタ" -> "豚ト豚"
        expect(result).to eq("豚ト豚")
      end

      it "applies multiple normalize word replacements" do
        result = described_class.call(
          string_sequence: "ぶたととり"
        )
        # "ぶたととり" -> "ブタトトリ" -> "豚ト鶏"
        expect(result).to eq("豚ト鶏")
      end

      it "replaces when source is kanji" do
        result = described_class.call(
          string_sequence: "鳥肉"
        )
        # "鳥肉" -> "鳥肉" (no kana conversion) -> "鶏肉" (db replacement)
        expect(result).to eq("鶏肉")
      end

      it "does not replace when no match found" do
        result = described_class.call(
          string_sequence: "まぐろ"
        )
        # "まぐろ" -> "マグロ" (no db replacement)
        expect(result).to eq("マグロ")
      end

      it "applies normalization before db lookup" do
        result = described_class.call(
          string_sequence: "ぶた　１２３"
        )
        # "ぶた　１２３" -> "ブタ 123" -> "豚 123"
        expect(result).to eq("豚 123")
      end
    end

    context "edge cases" do
      it "handles strings with no normalizable characters" do
        result = described_class.call(
          string_sequence: "漢字文字列",
          use_db_normalize_word: false
        )
        expect(result).to eq("漢字文字列")
      end

      it "preserves special characters" do
        result = described_class.call(
          string_sequence: "あ!@#$%",
          use_db_normalize_word: false
        )
        expect(result).to eq("ア!@#$%")
      end
    end

    context "with complex db replacements" do
      let!(:katsudon_normalize_word) do
        FactoryBot.create(:normalize_word_for_katsudon)
        # source: "カツ丼", destination: "カカカカカツツツツツ丼丼丼丼丼"
      end

      it "handles multi-character replacements" do
        result = described_class.call(
          string_sequence: "かつ丼"
        )
        # "かつ丼" -> "カツ丼" -> "カカカカカツツツツツ丼丼丼丼丼"
        expect(result).to eq("カカカカカツツツツツ丼丼丼丼丼")
      end
    end

    context "query performance" do
      let!(:normalize_word_pork) do
        FactoryBot.create(:normalize_word_from_kana_to_kanji)
      end

      it "does not cause N+1 queries when multiple words match" do
        # 1つのクエリで全てのNormalizeWordを取得する
        expect_query_count(1) do
          described_class.call(string_sequence: "ぶた")
        end
      end
    end
  end
end
