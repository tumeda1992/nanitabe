require "rails_helper"

RSpec.describe Business::Food::Dish::Source::Locator::LocatorCompatibility do
  describe ".supports?" do
    describe "book locator" do
      it "supports recipe book source type" do
        result = described_class.supports?(Business::Food::Dish::Source::Type::RECIPE_BOOK, :book)

        expect(result).to be true
      end

      it "does not support youtube source type" do
        result = described_class.supports?(Business::Food::Dish::Source::Type::YOUTUBE, :book)

        expect(result).to be false
      end

      it "does not support website source type" do
        result = described_class.supports?(Business::Food::Dish::Source::Type::WEBSITE, :book)

        expect(result).to be false
      end

      it "does not support restaurant source type" do
        result = described_class.supports?(Business::Food::Dish::Source::Type::RESTAURANT, :book)

        expect(result).to be false
      end

      it "does not support other source type" do
        result = described_class.supports?(Business::Food::Dish::Source::Type::OTHER, :book)

        expect(result).to be false
      end
    end

    describe "website locator" do
      it "supports youtube source type" do
        result = described_class.supports?(Business::Food::Dish::Source::Type::YOUTUBE, :website)

        expect(result).to be true
      end

      it "supports website source type" do
        result = described_class.supports?(Business::Food::Dish::Source::Type::WEBSITE, :website)

        expect(result).to be true
      end

      it "does not support recipe book source type" do
        result = described_class.supports?(Business::Food::Dish::Source::Type::RECIPE_BOOK, :website)

        expect(result).to be false
      end

      it "does not support restaurant source type" do
        result = described_class.supports?(Business::Food::Dish::Source::Type::RESTAURANT, :website)

        expect(result).to be false
      end

      it "does not support other source type" do
        result = described_class.supports?(Business::Food::Dish::Source::Type::OTHER, :website)

        expect(result).to be false
      end
    end

    describe "other locator" do
      it "supports recipe book source type" do
        result = described_class.supports?(Business::Food::Dish::Source::Type::RECIPE_BOOK, :other)

        expect(result).to be true
      end

      it "supports youtube source type" do
        result = described_class.supports?(Business::Food::Dish::Source::Type::YOUTUBE, :other)

        expect(result).to be true
      end

      it "supports website source type" do
        result = described_class.supports?(Business::Food::Dish::Source::Type::WEBSITE, :other)

        expect(result).to be true
      end

      it "supports restaurant source type" do
        result = described_class.supports?(Business::Food::Dish::Source::Type::RESTAURANT, :other)

        expect(result).to be true
      end

      it "supports other source type" do
        result = described_class.supports?(Business::Food::Dish::Source::Type::OTHER, :other)

        expect(result).to be true
      end
    end

    describe "unknown locator kind" do
      it "returns false for unknown kind" do
        result = described_class.supports?(Business::Food::Dish::Source::Type::RECIPE_BOOK, :unknown)

        expect(result).to be false
      end

      it "returns false for nil kind" do
        result = described_class.supports?(Business::Food::Dish::Source::Type::RECIPE_BOOK, nil)

        expect(result).to be false
      end
    end

    describe "string kind conversion" do
      it "converts string to symbol for book" do
        result = described_class.supports?(Business::Food::Dish::Source::Type::RECIPE_BOOK, "book")

        expect(result).to be true
      end

      it "converts string to symbol for website" do
        result = described_class.supports?(Business::Food::Dish::Source::Type::YOUTUBE, "website")

        expect(result).to be true
      end

      it "converts string to symbol for other" do
        result = described_class.supports?(Business::Food::Dish::Source::Type::OTHER, "other")

        expect(result).to be true
      end
    end
  end
end