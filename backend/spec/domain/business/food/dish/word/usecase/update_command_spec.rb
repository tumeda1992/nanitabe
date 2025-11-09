require "rails_helper"

RSpec.describe Business::Food::Dish::Word::Usecase::UpdateCommand do
  before do
    # 他のテストで作成されたDishをクリア
    Dish.delete_all
  end

  describe "validations" do
    let!(:normalize_word) do
      FactoryBot.create(:normalize_word_from_kana_to_kanji)
    end

    context "when normalize_word_id is missing" do
      it "raises validation error" do
        expect {
          described_class.call(source: "とり", destination: "鶏")
        }.to raise_error(/Normalize word can't be blank/)
      end
    end

    context "when normalize_word_id is nil" do
      it "raises validation error" do
        expect {
          described_class.call(normalize_word_id: nil, source: "とり", destination: "鶏")
        }.to raise_error(/Normalize word can't be blank/)
      end
    end

    context "when source is missing" do
      it "raises validation error" do
        expect {
          described_class.call(normalize_word_id: normalize_word.id, destination: "鶏")
        }.to raise_error(/Source can't be blank/)
      end
    end

    context "when source is nil" do
      it "raises validation error" do
        expect {
          described_class.call(normalize_word_id: normalize_word.id, source: nil, destination: "鶏")
        }.to raise_error(/Source can't be blank/)
      end
    end

    context "when destination is missing" do
      it "does not raise error" do
        expect {
          described_class.call(normalize_word_id: normalize_word.id, source: "とり")
        }.not_to raise_error
      end
    end
  end

  describe "#call" do
    let!(:normalize_word) do
      FactoryBot.create(:normalize_word_from_kana_to_kanji)
      # source: "ブタ", destination: "豚"
    end

    it "updates the existing normalize word" do
      described_class.call(
        normalize_word_id: normalize_word.id,
        source: "とり",
        destination: "鶏"
      )

      normalize_word.reload
      expect(normalize_word.entered_source).to eq("とり")
      expect(normalize_word.entered_destination).to eq("鶏")
    end

    it "updates the normalized values" do
      described_class.call(
        normalize_word_id: normalize_word.id,
        source: "とり",
        destination: "鶏"
      )

      normalize_word.reload
      # 基本正規化が適用される（ひらがな→カタカナ）
      expect(normalize_word.source).to eq("トリ")
      expect(normalize_word.destination).to eq("鶏")
    end

    it "normalizes full-width characters" do
      described_class.call(
        normalize_word_id: normalize_word.id,
        source: "ａｂｃ",
        destination: "ＸＹＺ"
      )

      normalize_word.reload
      expect(normalize_word.source).to eq("abc")
      expect(normalize_word.destination).to eq("XYZ")
    end

    it "calls ReflectLatestNormalizeWordCommand to re-normalize all dishes" do
      # ReflectLatestNormalizeWordCommandが呼ばれることを確認
      expect(Business::Food::Dish::Word::Usecase::ReflectLatestNormalizeWordCommand)
        .to receive(:call)

      described_class.call(
        normalize_word_id: normalize_word.id,
        source: "とり",
        destination: "鶏"
      )
    end

    context "when the normalize word does not exist" do
      it "raises an error" do
        expect {
          described_class.call(
            normalize_word_id: 99999,
            source: "とり",
            destination: "鶏"
          )
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "when destination is nil" do
      it "updates with source as destination" do
        described_class.call(
          normalize_word_id: normalize_word.id,
          source: "とり",
          destination: nil
        )

        normalize_word.reload
        expect(normalize_word.entered_source).to eq("とり")
        expect(normalize_word.entered_destination).to eq("")
        expect(normalize_word.source).to eq("トリ")
        expect(normalize_word.destination).to eq("トリ")
      end
    end

    context "integration test" do
      let!(:dish) do
        Dish.create!(
          user: FactoryBot.create(:user, id_param: "user_for_update_test"),
          name: "ぶた肉",
          normalized_name: "豚肉",
          meal_position: 1
        )
      end

      it "updates the normalize word and re-normalizes dishes" do
        # 更新前: "ぶた肉" -> "豚肉" ("ブタ" -> "豚" が適用されている)
        expect(dish.normalized_name).to eq("豚肉")

        # "ブタ" -> "豚" を "ブタ" -> "ポーク" に変更
        described_class.call(
          normalize_word_id: normalize_word.id,
          source: "ぶた",
          destination: "ポーク"
        )

        dish.reload
        # 更新後: "ぶた肉" -> "ポーク肉" (新しいルールが適用される)
        expect(dish.normalized_name).to eq("ポーク肉")
      end
    end
  end
end
