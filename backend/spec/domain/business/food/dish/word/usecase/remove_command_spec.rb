require "rails_helper"

RSpec.describe Business::Food::Dish::Word::Usecase::RemoveCommand do
  before do
    # 他のテストで作成されたDishをクリア
    Dish.delete_all
  end

  describe "validations" do
    context "when normalize_word_id is nil" do
      it "raises error" do
        expect {
          described_class.call(normalize_word_id: nil)
        }.to raise_error(Business::Base::Values::InvalidAttributeError)
      end
    end
  end

  describe "#call" do
    let!(:normalize_word) do
      FactoryBot.create(:normalize_word_from_kana_to_kanji)
      # source: "ブタ", destination: "豚"
    end

    it "deletes the normalize word" do
      expect {
        described_class.call(normalize_word_id: normalize_word.id)
      }.to change { NormalizeWord.count }.by(-1)

      expect(NormalizeWord.find_by(id: normalize_word.id)).to be_nil
    end

    it "calls ReflectLatestNormalizeWordCommand to re-normalize all dishes" do
      # ReflectLatestNormalizeWordCommandが呼ばれることを確認
      expect(Business::Food::Dish::Word::Usecase::ReflectLatestNormalizeWordCommand)
        .to receive(:call)

      described_class.call(normalize_word_id: normalize_word.id)
    end

    context "when the normalize word does not exist" do
      it "raises an error" do
        expect {
          described_class.call(normalize_word_id: 99999)
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "integration test" do
      let!(:dish) do
        Dish.create!(
          user: FactoryBot.create(:user, id_param: "user_for_remove_test"),
          name: "ぶた肉",
          normalized_name: "豚肉",
          meal_position: 1
        )
      end

      it "removes the normalize word and re-normalizes dishes" do
        # 削除前: "ぶた肉" -> "豚肉" (normalize_wordで "ブタ" -> "豚" が適用されている)
        expect(dish.normalized_name).to eq("豚肉")

        described_class.call(normalize_word_id: normalize_word.id)

        dish.reload
        # 削除後: "ぶた肉" -> "ブタ肉" (normalize_wordが削除されたので基本正規化のみ)
        expect(dish.normalized_name).to eq("ブタ肉")
      end
    end
  end
end
