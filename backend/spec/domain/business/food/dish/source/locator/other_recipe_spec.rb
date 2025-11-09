require "rails_helper"

RSpec.describe Business::Food::Dish::Source::Locator::OtherRecipe do
  describe "#initialize" do
    it "creates instance with memo" do
      memo = "テレビで見たレシピ"
      locator = described_class.new(memo)

      expect(locator.memo).to eq(memo)
    end

    it "accepts nil memo" do
      locator = described_class.new(nil)

      expect(locator.memo).to be_nil
    end

    it "accepts empty string memo" do
      locator = described_class.new("")

      expect(locator.memo).to eq("")
    end
  end

  describe "#kind" do
    it "returns :other" do
      locator = described_class.new("memo")

      expect(locator.kind).to eq(:other)
    end
  end

  describe "#detail_value" do
    it "returns memo" do
      memo = "手作りレシピ"
      locator = described_class.new(memo)

      expect(locator.detail_value).to eq memo
    end

    it "returns nil" do
      locator = described_class.new(nil)

      expect(locator.detail_value).to eq nil
    end
  end

  describe "#==" do
    let(:memo) { "同じメモ" }
    let(:locator1) { described_class.new(memo) }
    let(:locator2) { described_class.new(memo) }
    let(:locator3) { described_class.new("違うメモ") }

    it "returns true for same memo" do
      expect(locator1 == locator2).to be true
    end

    it "returns false for different memo" do
      expect(locator1 == locator3).to be false
    end

    it "returns false for different class" do
      other_class_instance = double("OtherClass", class: String, to_h: { memo: memo })
      expect(locator1 == other_class_instance).to be false
    end
  end
end
