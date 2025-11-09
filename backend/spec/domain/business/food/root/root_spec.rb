require "rails_helper"

RSpec.describe Business::Food::Dish::Root, type: :model do
  let(:user_id) { 1 }
  let(:dish_name) do
    ::Business::Food::Dish::Name.new(
      value: "test_dish",
      normalized: "test_normalized",
    )
  end
  let(:meal_position) { 1 }
  let(:comment) { "test_comment" }

  # TODO: subject.set_idとかのテストがされているから、めっちゃきもい
  subject { Business::Food::Dish::Root.new(user_id: user_id, name: dish_name, meal_position: meal_position, comment: comment) }

  describe "validations" do
    it { should validate_presence_of(:user_id) }
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:meal_position) }
  end

  describe "#set_id" do
    let(:new_id) { 123 }

    context "when id is not present" do
      it "sets id successfully" do
        subject.set_id(new_id)

        expect(subject.id).to eq(new_id)
      end
    end

    context "when id is already present" do
      before { subject.id = 456 }

      it "raises error" do
        expect { subject.set_id(new_id) }.to raise_error("新規作成時以外idを変更できません")
      end
    end
  end

  describe "#rename" do
    let(:new_name) { "new_dish_name" }
    let(:normalized_new_name) { "new_dish_name_normalized" }

    before do
      allow(::Business::Food::Dish::Word::Usecase::NormalizeCommand)
        .to receive(:call)
        .with(string_sequence: new_name)
        .and_return(normalized_new_name)
    end

    it "updates name and normalized_name" do
      subject.rename(new_name)

      expect(subject.name.value).to eq(new_name)
      expect(subject.name.normalized).to eq(normalized_new_name)
    end

    context "when new_name is blank" do
      it "raises error" do
        expect { subject.rename("") }.to raise_error("料理名は空にできません。")
        expect { subject.rename(nil) }.to raise_error("料理名は空にできません。")
      end
    end
  end

  describe "#reposition_in_meal" do
    let(:new_meal_position) { 2 }

    it "updates meal_position" do
      subject.reposition_in_meal(new_meal_position)

      expect(subject.meal_position).to eq(new_meal_position)
    end

    context "when new_meal_position is blank" do
      it "raises error" do
        expect { subject.reposition_in_meal("") }.to raise_error("料理の位置は空にできません。")
        expect { subject.reposition_in_meal(nil) }.to raise_error("料理の位置は空にできません。")
      end
    end
  end

  describe "#revice_comment" do
    let(:new_comment) { "new_comment" }

    it "updates comment" do
      subject.revise_comment(new_comment)

      expect(subject.comment).to eq(new_comment)
    end

    it "allows blank comment" do
      subject.revise_comment("")
      expect(subject.comment).to eq("")

      subject.revise_comment(nil)
      expect(subject.comment).to be_nil
    end
  end

  describe "#attach_source" do
    let(:recipe_book_source_id) { 123 }
    let(:youtube_source_id) { 456 }
    let(:existing_source_id) { 789 }
    let(:book_page) { 123 }
    let(:website_url) { "https://example.com" }

    let(:recipe_book_source) { double("source", id: recipe_book_source_id, type: Business::Food::Dish::Source::Type.recipe_book) }
    let(:youtube_source) { double("source", id: youtube_source_id, type: Business::Food::Dish::Source::Type.youtube) }
    let(:book_locator) { Business::Food::Dish::Source::Locator::RecipeBook.new(book_page) }
    let(:website_locator) { Business::Food::Dish::Source::Locator::RecipeWebsite.new(website_url) }

    before do
      # DishSourceの存在チェックのモックを設定
      allow(::DishSource).to receive(:where).with(id: recipe_book_source_id).and_return(double(exists?: true))
      allow(::DishSource).to receive(:where).with(id: youtube_source_id).and_return(double(exists?: true))
      allow(::DishSource).to receive(:where).with(id: existing_source_id).and_return(double(exists?: true))
    end

    context "with valid source and compatible locator" do
      it "attaches source_id and source_locator" do
        subject.attach_source(recipe_book_source, book_locator)

        expect(subject.source_id).to eq(recipe_book_source_id)
        expect(subject.source_locator).to eq(book_locator)
      end
    end

    context "when source is blank" do
      it "raises error for empty string" do
        expect { subject.attach_source("", book_locator) }.to raise_error("関連付けるレシピ元が指定されていません。")
      end

      it "raises error for nil" do
        expect { subject.attach_source(nil, book_locator) }.to raise_error("関連付けるレシピ元が指定されていません。")
      end
    end

    context "when policy validation fails" do
      it "raises error for incompatible source and locator" do
        expect { subject.attach_source(youtube_source, book_locator) }.to raise_error("料理へのレシピ元関連付けにおいて、レシピ元に対して、Locatorの指定が誤っています (locator_kind: book, source_type: 2)")
      end
    end

    context "when source is already attached" do
      before do
        subject.source_id = existing_source_id
        subject.source_locator = website_locator
      end

      it "overwrites existing source_id and source_locator" do
        subject.attach_source(recipe_book_source, book_locator)

        expect(subject.source_id).to eq(recipe_book_source_id)
        expect(subject.source_locator).to eq(book_locator)
      end
    end
  end

  describe "#detach_source" do
    context "when source is attached" do
      before { subject.source_id = 123 }

      it "removes source_id" do
        subject.detach_source

        expect(subject.source_id).to be_nil
      end
    end

    context "when source is not attached" do
      before { subject.source_id = nil }

      it "keeps source_id as nil" do
        subject.detach_source

        expect(subject.source_id).to be_nil
      end
    end
  end
end
