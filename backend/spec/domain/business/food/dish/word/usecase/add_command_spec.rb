require "rails_helper"

RSpec.describe Business::Food::Dish::Word::Usecase::AddCommand do
  before do
    # 他のテストで作成されたDishをクリア
    Dish.delete_all
  end

  describe "validations" do
    context "when source is missing" do
      it "raises validation error" do
        expect {
          described_class.call(destination: "豚")
        }.to raise_error(/Source can't be blank/)
      end
    end

    context "when source is nil" do
      it "raises validation error" do
        expect {
          described_class.call(source: nil, destination: "豚")
        }.to raise_error(/Source can't be blank/)
      end
    end

    context "when source is empty string" do
      it "raises validation error" do
        expect {
          described_class.call(source: "", destination: "豚")
        }.to raise_error(/Source can't be blank/)
      end
    end

    context "when destination is missing" do
      it "does not raise error" do
        expect {
          described_class.call(source: "ぶた")
        }.not_to raise_error
      end
    end
  end

  describe "#call" do
    it "creates a new normalize word" do
      expect {
        described_class.call(source: "ぶた", destination: "豚")
      }.to change { NormalizeWord.count }.by(1)
    end

    it "saves the entered values" do
      described_class.call(source: "ぶた", destination: "豚")

      normalize_word = NormalizeWord.last
      expect(normalize_word.entered_source).to eq("ぶた")
      expect(normalize_word.entered_destination).to eq("豚")
    end

    it "saves the normalized values" do
      described_class.call(source: "ぶた", destination: "豚")

      normalize_word = NormalizeWord.last
      # 基本正規化が適用される（ひらがな→カタカナ）
      expect(normalize_word.source).to eq("ブタ")
      expect(normalize_word.destination).to eq("豚")
    end

    it "normalizes full-width characters" do
      described_class.call(source: "ａｂｃ", destination: "ＸＹＺ")

      normalize_word = NormalizeWord.last
      expect(normalize_word.source).to eq("abc")
      expect(normalize_word.destination).to eq("XYZ")
    end

    it "calls ReflectLatestNormalizeWordCommand to re-normalize all dishes" do
      # ReflectLatestNormalizeWordCommandが呼ばれることを確認
      expect(Business::Food::Dish::Word::Usecase::ReflectLatestNormalizeWordCommand)
        .to receive(:call)

      described_class.call(source: "ぶた", destination: "豚")
    end

    context "when destination is nil" do
      it "creates normalize word with empty string destination" do
        described_class.call(source: "ぶた", destination: nil)

        normalize_word = NormalizeWord.last
        expect(normalize_word.entered_source).to eq("ぶた")
        expect(normalize_word.entered_destination).to eq("")
        expect(normalize_word.source).to eq("ブタ")
        expect(normalize_word.destination).to eq("ブタ")
      end
    end

    context "integration test" do
      let!(:dish) do
        Dish.create!(
          user: FactoryBot.create(:user, id_param: "user_for_add_test"),
          name: "ぶた肉",
          normalized_name: "ブタ肉",
          meal_position: 1,
        )
      end

      it "adds a new normalize word and re-normalizes dishes" do
        # 追加前: "ぶた肉" -> "ブタ肉" (基本正規化のみ)
        expect(dish.normalized_name).to eq("ブタ肉")

        described_class.call(source: "ぶた", destination: "豚")

        dish.reload
        # 追加後: "ぶた肉" -> "豚肉" (新しいnormalize_wordが適用される)
        expect(dish.normalized_name).to eq("豚肉")
      end
    end
  end
end
