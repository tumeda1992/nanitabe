require "rails_helper"

RSpec.describe Business::Food::Dish::Source::Root, type: :model do
  let(:user_id) { 1 }
  let(:source_name) { "test_source" }
  let(:source_type) { Business::Food::Dish::Source::Type.recipe_book.value }
  let(:comment) { "test_comment" }

  subject { Business::Food::Dish::Source::Root.new(user_id: user_id, name: source_name, type: source_type, comment: comment) }

  describe "validations" do
    it { should validate_presence_of(:user_id) }
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:type) }
  end

  describe "#rename" do
    let(:new_name) { "new_source_name" }

    it "updates name" do
      subject.rename(new_name)

      expect(subject.name).to eq(new_name)
    end

    context "when new_name is blank" do
      it "raises error" do
        expect { subject.rename("") }.to raise_error("レシピ元名は空にできません。")
        expect { subject.rename(nil) }.to raise_error("レシピ元名は空にできません。")
      end
    end
  end

  describe "#change_type" do
    let(:new_type) { Business::Food::Dish::Source::Type.youtube }

    it "updates type" do
      subject.change_type(new_type)

      expect(subject.type.value).to eq(new_type.value)
    end

    context "when new_type is blank" do
      it "raises error" do
        expect { subject.change_type("") }.to raise_error("レシピ元の種別は空にできません。")
        expect { subject.change_type(nil) }.to raise_error("レシピ元の種別は空にできません。")
      end
    end
  end

  describe "#revise_comment" do
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
end