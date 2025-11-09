require "rails_helper"

RSpec.describe Business::Food::Dish::Source::Usecase::Params::Source do
  let(:source_name) { "test_source" }
  let(:source_type) { Business::Food::Dish::Source::Type.recipe_book.value }
  let(:comment) { "test_comment" }

  describe "validations for create" do
    subject { described_class.new(:create, name: source_name, type: source_type, comment: comment) }

    it { should be_valid }

    context "when id is present" do
      it "raises error" do
        expect { described_class.new(:create, id: 1, name: source_name, type: source_type) }.to raise_error(/Id must be blank/)
      end
    end

    context "when name is blank" do
      it "raises error" do
        expect { described_class.new(:create, name: nil, type: source_type) }.to raise_error(/Name can't be blank/)
      end
    end

    context "when type is blank" do
      it "raises error" do
        expect { described_class.new(:create, name: source_name, type: nil) }.to raise_error(/Type can't be blank/)
      end
    end

    context "when comment is blank" do
      subject { described_class.new(:create, name: source_name, type: source_type, comment: nil) }

      it { should be_valid }
    end
  end

  describe "validations for update" do
    subject { described_class.new(:update, id: 1, name: source_name, type: source_type, comment: comment) }

    it { should be_valid }

    context "when id is blank" do
      it "raises error" do
        expect { described_class.new(:update, id: nil, name: source_name, type: source_type) }.to raise_error(/Id can't be blank/)
      end
    end

    context "when name is blank" do
      subject { described_class.new(:update, id: 1, name: nil, type: source_type) }

      it { should be_valid }
    end

    context "when type is blank" do
      subject { described_class.new(:update, id: 1, name: source_name, type: nil) }

      it { should be_valid }
    end
  end

  describe "#valid_for_create?" do
    it "returns true when valid for create context" do
      params = described_class.new(:create, name: source_name, type: source_type)
      expect(params.valid_for_create?).to be true
    end
  end

  describe "#valid_for_update?" do
    it "returns true when valid for update context" do
      params = described_class.new(:update, id: 1, name: source_name)
      expect(params.valid_for_update?).to be true
    end
  end
end