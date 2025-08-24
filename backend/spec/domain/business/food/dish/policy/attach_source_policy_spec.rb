require "rails_helper"

RSpec.describe Business::Food::Dish::Policy::AttachSourcePolicy do
  describe ".ok?" do
    context "both source and source_locator are nil" do
      it "returns true" do
        result = described_class.ok?(nil, nil)

        expect(result).to be true
      end
    end

    context "source is nil but source_locator is not nil" do
      let(:source_locator) { Business::Food::Dish::Source::Locator::RecipeBook.new(123) }

      it "returns false" do
        result = described_class.ok?(nil, source_locator)

        expect(result).to be false
      end
    end

    context "source is not nil but source_locator is nil" do
      let(:source) { double("source", type: Business::Food::Dish::Source::Type::RECIPE_BOOK) }

      it "returns false" do
        result = described_class.ok?(source, nil)

        expect(result).to be false
      end
    end

    context "both source and source_locator are present" do
      let(:recipe_book_source) { double("source", type: Business::Food::Dish::Source::Type::RECIPE_BOOK) }
      let(:youtube_source) { double("source", type: Business::Food::Dish::Source::Type::YOUTUBE) }
      let(:website_source) { double("source", type: Business::Food::Dish::Source::Type::WEBSITE) }

      let(:book_locator) { Business::Food::Dish::Source::Locator::RecipeBook.new(123) }
      let(:website_locator) { Business::Food::Dish::Source::Locator::RecipeWebsite.new("https://example.com") }
      let(:other_locator) { Business::Food::Dish::Source::Locator::OtherRecipe.new("memo") }

      context "compatible source type and locator kind" do
        it "returns true for recipe book source with book locator" do
          result = described_class.ok?(recipe_book_source, book_locator)

          expect(result).to be true
        end

        it "returns true for youtube source with website locator" do
          result = described_class.ok?(youtube_source, website_locator)

          expect(result).to be true
        end

        it "returns true for website source with website locator" do
          result = described_class.ok?(website_source, website_locator)

          expect(result).to be true
        end

        it "returns true for any source with other locator" do
          result = described_class.ok?(recipe_book_source, other_locator)

          expect(result).to be true
        end
      end

      context "incompatible source type and locator kind" do
        it "returns false for recipe book source with website locator" do
          result = described_class.ok?(recipe_book_source, website_locator)

          expect(result).to be false
        end

        it "returns false for youtube source with book locator" do
          result = described_class.ok?(youtube_source, book_locator)

          expect(result).to be false
        end

        it "returns false for website source with book locator" do
          result = described_class.ok?(website_source, book_locator)

          expect(result).to be false
        end
      end
    end
  end
end