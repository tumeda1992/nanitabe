require "rails_helper"

RSpec.describe Business::Food::Dish::Source::Locator::Factory do
  describe ".build" do
    describe "book locator" do
      it "creates RecipeBook locator with page" do
        page = 123
        locator = described_class.build(:book, page: page)

        expect(locator).to be_an_instance_of(Business::Food::Dish::Source::Locator::RecipeBook)
        expect(locator.page).to eq(page)
      end

      it "raises error when page is missing" do
        expect { described_class.build(:book) }.to raise_error(ArgumentError, "page must be a positive integer")
      end

      it "raises error when page is invalid" do
        expect { described_class.build(:book, page: 0) }.to raise_error(ArgumentError, "page must be a positive integer")
      end
    end

    describe "website locator" do
      it "creates Website locator with url" do
        url = "https://example.com"
        locator = described_class.build(:website, url: url)

        expect(locator).to be_an_instance_of(Business::Food::Dish::Source::Locator::RecipeWebsite)
        expect(locator.url).to eq(url)
      end

      it "raises error when url is missing" do
        expect { described_class.build(:website) }.to raise_error(ArgumentError)
      end

      it "raises error when url is invalid" do
        expect { described_class.build(:website, url: "invalid-url") }.to raise_error(ArgumentError, "Invalid URL")
      end
    end

    describe "other locator" do
      it "creates OtherRecipe locator with memo" do
        memo = "テレビのレシピ"
        locator = described_class.build(:other, memo: memo)

        expect(locator).to be_an_instance_of(Business::Food::Dish::Source::Locator::OtherRecipe)
        expect(locator.memo).to eq(memo)
      end

      it "creates OtherRecipe locator with nil memo" do
        locator = described_class.build(:other)

        expect(locator).to be_an_instance_of(Business::Food::Dish::Source::Locator::OtherRecipe)
        expect(locator.memo).to be_nil
      end
    end

    describe "unknown locator kind" do
      it "raises error for unknown kind" do
        expect { described_class.build(:unknown) }.to raise_error(ArgumentError, "Unknown locator kind: unknown")
      end

      it "raises error for nil kind" do
        expect { described_class.build(nil) }.to raise_error(ArgumentError, "Unknown locator kind: ")
      end
    end

    describe "string kind conversion" do
      it "accepts string kind for book" do
        locator = described_class.build("book", page: 123)

        expect(locator).to be_an_instance_of(Business::Food::Dish::Source::Locator::RecipeBook)
      end

      it "accepts string kind for website" do
        locator = described_class.build("website", url: "https://example.com")

        expect(locator).to be_an_instance_of(Business::Food::Dish::Source::Locator::RecipeWebsite)
      end

      it "accepts string kind for other" do
        locator = described_class.build("other", memo: "memo")

        expect(locator).to be_an_instance_of(Business::Food::Dish::Source::Locator::OtherRecipe)
      end
    end
  end
end