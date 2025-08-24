require "rails_helper"

RSpec.describe Business::Food::Dish::Source::Locator::RecipeWebsite do
  describe "#initialize" do
    context "with valid URL" do
      it "creates instance with HTTP URL" do
        locator = described_class.new("http://example.com")

        expect(locator.url).to eq("http://example.com")
      end

      it "creates instance with HTTPS URL" do
        locator = described_class.new("https://example.com/recipe")

        expect(locator.url).to eq("https://example.com/recipe")
      end
    end

    context "with invalid URL" do
      it "raises error for non-HTTP URL" do
        expect { described_class.new("ftp://example.com") }.to raise_error(ArgumentError, "Invalid URL")
      end

      it "raises error for malformed URL" do
        expect { described_class.new("not-a-url") }.to raise_error(ArgumentError, "Invalid URL")
      end

      it "raises error for empty string" do
        expect { described_class.new("") }.to raise_error(ArgumentError, "Invalid URL")
      end

      it "raises error for nil" do
        expect { described_class.new(nil) }.to raise_error(ArgumentError)
      end
    end
  end

  describe "#kind" do
    it "returns :website" do
      locator = described_class.new("https://example.com")

      expect(locator.kind).to eq(:website)
    end
  end

  describe "#to_h" do
    it "returns hash with url" do
      url = "https://example.com/recipe"
      locator = described_class.new(url)

      expect(locator.to_h).to eq({ url: url })
    end
  end

  describe "#==" do
    let(:url) { "https://example.com" }
    let(:locator1) { described_class.new(url) }
    let(:locator2) { described_class.new(url) }
    let(:locator3) { described_class.new("https://other.com") }

    it "returns true for same URL" do
      expect(locator1 == locator2).to be true
    end

    it "returns false for different URL" do
      expect(locator1 == locator3).to be false
    end

    it "returns false for different class" do
      other_class_instance = double("OtherClass", class: String, to_h: { url: url })
      expect(locator1 == other_class_instance).to be false
    end
  end
end