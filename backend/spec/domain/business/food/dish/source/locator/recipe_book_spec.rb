require "rails_helper"

RSpec.describe Business::Food::Dish::Source::Locator::RecipeBook do
  describe "#initialize" do
    context "with valid page number" do
      it "creates instance with integer page" do
        locator = described_class.new(123)

        expect(locator.page).to eq(123)
      end

      it "converts string page to integer" do
        locator = described_class.new("456")

        expect(locator.page).to eq(456)
      end
    end

    context "with invalid page number" do
      it "raises error for zero page" do
        expect { described_class.new(0) }.to raise_error(ArgumentError, "page must be a positive integer")
      end

      it "raises error for negative page" do
        expect { described_class.new(-1) }.to raise_error(ArgumentError, "page must be a positive integer")
      end

      it "raises error for non-numeric string" do
        expect { described_class.new("abc") }.to raise_error(ArgumentError, "page must be a positive integer")
      end
    end
  end

  describe "#kind" do
    it "returns :book" do
      locator = described_class.new(1)

      expect(locator.kind).to eq(:book)
    end
  end

  describe "#to_h" do
    it "returns hash with page" do
      locator = described_class.new(123)

      expect(locator.to_h).to eq({ page: 123 })
    end
  end

  describe "#==" do
    let(:locator1) { described_class.new(123) }
    let(:locator2) { described_class.new(123) }
    let(:locator3) { described_class.new(456) }

    it "returns true for same page" do
      expect(locator1 == locator2).to be true
    end

    it "returns false for different page" do
      expect(locator1 == locator3).to be false
    end

    it "returns false for different class" do
      other_class_instance = double("OtherClass", class: String, to_h: { page: 123 })
      expect(locator1 == other_class_instance).to be false
    end
  end
end