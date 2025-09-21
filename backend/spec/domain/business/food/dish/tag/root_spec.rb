require "rails_helper"

RSpec.describe Business::Food::Dish::Tag::Root, type: :model do
  let(:user_id) { 1 }
  let(:content) { Business::Food::Dish::Tag::Content.new(value: "辛い", normalized: "辛い") }

  describe "validations" do
    it "is valid with valid attributes" do
      root = described_class.new(user_id: user_id, content: content)
      expect(root).to be_valid
    end

    it "raises error without user_id" do
      expect {
        described_class.new(content: content)
      }.to raise_error(Business::Base::Values::InvalidAttributeError, "User can't be blank")
    end

    it "raises error without content" do
      expect {
        described_class.new(user_id: user_id)
      }.to raise_error(Business::Base::Values::InvalidAttributeError, "Content can't be blank")
    end

    it "raises error with nil user_id" do
      expect {
        described_class.new(user_id: nil, content: content)
      }.to raise_error(Business::Base::Values::InvalidAttributeError, "User can't be blank")
    end

    it "raises error with nil content" do
      expect {
        described_class.new(user_id: user_id, content: nil)
      }.to raise_error(Business::Base::Values::InvalidAttributeError, "Content can't be blank")
    end
  end

  describe "#set_id" do
    let(:root) { described_class.new(user_id: user_id, content: content) }

    context "when id is not set yet" do
      it "sets the id" do
        root.set_id(123)
        expect(root.id).to eq(123)
      end
    end

    context "when id is already set" do
      before { root.set_id(123) }

      it "raises error" do
        expect {
          root.set_id(456)
        }.to raise_error("新規作成時以外idを変更できません")
      end
    end
  end

  describe "attributes access" do
    let(:root) { described_class.new(id: 123, user_id: user_id, content: content) }

    it "allows access to id" do
      expect(root.id).to eq(123)
    end

    it "allows access to user_id" do
      expect(root.user_id).to eq(user_id)
    end

    it "allows access to content" do
      expect(root.content).to eq(content)
    end
  end
end