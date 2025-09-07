require "rails_helper"

RSpec.describe Business::Food::Dish::Policy::AttachSourcePolicy do
  describe ".ensure!" do
    context "both source and source_locator are nil" do
      it "returns true" do
        result = described_class.ensure!(nil, nil)

        expect(result).to be true
      end
    end

    context "source is nil but source_locator is not nil" do
      let(:source_locator) { Business::Food::Dish::Source::Locator::RecipeBook.new(123) }

      it "raises an error" do
        expect {
          described_class.ensure!(nil, source_locator)
        }.to raise_error("料理へのレシピ元関連付けにおいて、レシピ元が指定されていません")
      end
    end

    context "source is not nil but source_locator is nil" do
      let(:source) { double("source", type: Business::Food::Dish::Source::Type::RECIPE_BOOK) }

      it "raises an error" do
        expect {
          described_class.ensure!(source, nil)
        }.to raise_error("料理へのレシピ元関連付けにおいて、レシピ元へのLocatorが指定されていません")
      end
    end

    context "both source and source_locator are present" do
      let(:recipe_book_source) { double("source", type: Business::Food::Dish::Source::Type.recipe_book) }
      let(:youtube_source) { double("source", type: Business::Food::Dish::Source::Type.youtube) }
      let(:website_source) { double("source", type: Business::Food::Dish::Source::Type.website) }

      let(:book_locator) { Business::Food::Dish::Source::Locator::RecipeBook.new(123) }
      let(:website_locator) { Business::Food::Dish::Source::Locator::RecipeWebsite.new("https://example.com") }
      let(:other_locator) { Business::Food::Dish::Source::Locator::OtherRecipe.new("memo") }

      context "compatible source type and locator kind" do
        it "returns true for recipe book source with book locator" do
          result = described_class.ensure!(recipe_book_source, book_locator)

          expect(result).to be true
        end

        it "returns true for youtube source with website locator" do
          result = described_class.ensure!(youtube_source, website_locator)

          expect(result).to be true
        end

        it "returns true for website source with website locator" do
          result = described_class.ensure!(website_source, website_locator)

          expect(result).to be true
        end

        it "returns true for any source with other locator" do
          result = described_class.ensure!(recipe_book_source, other_locator)

          expect(result).to be true
        end
      end

      context "incompatible source type and locator kind" do
        it "raises an error for recipe book source with website locator" do
          expect {
            described_class.ensure!(recipe_book_source, website_locator)
          }.to raise_error(/料理へのレシピ元関連付けにおいて、レシピ元に対して、Locatorの指定が誤っています/)
        end

        it "raises an error for youtube source with book locator" do
          expect {
            described_class.ensure!(youtube_source, book_locator)
          }.to raise_error(/料理へのレシピ元関連付けにおいて、レシピ元に対して、Locatorの指定が誤っています/)
        end

        it "raises an error for website source with book locator" do
          expect {
            described_class.ensure!(website_source, book_locator)
          }.to raise_error(/料理へのレシピ元関連付けにおいて、レシピ元に対して、Locatorの指定が誤っています/)
        end
      end
    end
  end
end
