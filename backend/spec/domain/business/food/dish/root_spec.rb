require "rails_helper"

RSpec.describe Business::Food::Dish::Root do
  describe "#renormalize_name" do
    let(:original_name) do
      Business::Food::Dish::Name.new(
        value: "ひらがな料理",
        normalized: "OLD_NORMALIZED_VALUE",
      )
    end

    let(:root) do
      described_class.new(
        user_id: 1,
        name: original_name,
        meal_position: 1,
      )
    end

    it "re-normalizes the name using the current name value" do
      # Name.initialize_and_normalize が呼ばれることを確認
      expect(Business::Food::Dish::Name).to receive(:initialize_and_normalize)
        .with("ひらがな料理")
        .and_call_original

      root.renormalize_name

      # name が更新されている
      expect(root.name.value).to eq("ひらがな料理")
      expect(root.name.normalized).not_to eq("OLD_NORMALIZED_VALUE")
      # 基本的な正規化が適用されている
      expect(root.name.normalized).to eq("ヒラガナ料理")
    end

    it "preserves the original name value" do
      root.renormalize_name

      # value は変わらない
      expect(root.name.value).to eq("ひらがな料理")
    end

    it "updates the normalized value" do
      old_normalized = root.name.normalized

      root.renormalize_name

      # normalized が更新される
      expect(root.name.normalized).not_to eq(old_normalized)
    end

    context "when normalization rules change" do
      it "applies the latest normalization" do
        # 初回の正規化
        allow(Business::Food::Dish::Name).to receive(:initialize_and_normalize)
          .with("test")
          .and_return(Business::Food::Dish::Name.new(value: "test", normalized: "NORMALIZED_V1"))

        root_with_old_norm = described_class.new(
          user_id: 1,
          name: Business::Food::Dish::Name.new(value: "test", normalized: "NORMALIZED_V1"),
          meal_position: 1,
        )

        # 正規化ルールが変わった
        allow(Business::Food::Dish::Name).to receive(:initialize_and_normalize)
          .with("test")
          .and_return(Business::Food::Dish::Name.new(value: "test", normalized: "NORMALIZED_V2"))

        root_with_old_norm.renormalize_name

        # 新しい正規化ルールが適用される
        expect(root_with_old_norm.name.normalized).to eq("NORMALIZED_V2")
      end
    end
  end
end
