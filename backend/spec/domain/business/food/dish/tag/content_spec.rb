require "rails_helper"

RSpec.describe Business::Food::Dish::Tag::Content, type: :model do
  describe "validations" do
    it "is valid with valid attributes" do
      content = described_class.new(value: "辛い", normalized: "辛い")
      expect(content).to be_valid
    end

    it "raises error without value" do
      expect {
        described_class.new(normalized: "辛い")
      }.to raise_error(Business::Base::Values::InvalidAttributeError, "Value can't be blank")
    end

    it "raises error without normalized" do
      expect {
        described_class.new(value: "辛い")
      }.to raise_error(Business::Base::Values::InvalidAttributeError, "Normalized can't be blank")
    end

    it "raises error with empty value" do
      expect {
        described_class.new(value: "", normalized: "辛い")
      }.to raise_error(Business::Base::Values::InvalidAttributeError, "Value can't be blank")
    end

    it "raises error with empty normalized" do
      expect {
        described_class.new(value: "辛い", normalized: "")
      }.to raise_error(Business::Base::Values::InvalidAttributeError, "Normalized can't be blank")
    end
  end

  describe ".initialize_and_normalize" do
    let(:value) { "辛 い 料理" }
    let(:normalized_value) { "辛い料理" }

    before do
      allow(Business::Dish::Word::Normalize::Command::NormalizeCommand)
        .to receive(:call)
        .with(string_sequence: value)
        .and_return(normalized_value)
    end

    it "creates content with normalized value" do
      content = described_class.initialize_and_normalize(value)

      expect(content.value).to eq(value)
      expect(content.normalized).to eq(normalized_value)
      expect(content).to be_valid
    end

    it "calls the normalize command" do
      described_class.initialize_and_normalize(value)

      expect(Business::Dish::Word::Normalize::Command::NormalizeCommand)
        .to have_received(:call)
        .with(string_sequence: value)
    end
  end

  describe ".initialize_with_normalizing_if_need" do
    let(:value) { "辛 い 料理" }
    let(:normalized_value) { "辛い料理" }

    before do
      allow(Business::Dish::Word::Normalize::Command::NormalizeCommand)
        .to receive(:call)
        .with(string_sequence: value)
        .and_return(normalized_value)
    end

    context "when normalized is provided" do
      let(:provided_normalized) { "提供された正規化値" }

      it "uses provided normalized value" do
        content = described_class.initialize_with_normalizing_if_need(value, provided_normalized)

        expect(content.value).to eq(value)
        expect(content.normalized).to eq(provided_normalized)
        expect(content).to be_valid
      end

      it "does not call normalize command" do
        described_class.initialize_with_normalizing_if_need(value, provided_normalized)

        expect(Business::Dish::Word::Normalize::Command::NormalizeCommand)
          .not_to have_received(:call)
      end
    end

    context "when normalized is blank" do
      it "normalizes the value" do
        content = described_class.initialize_with_normalizing_if_need(value, "")

        expect(content.value).to eq(value)
        expect(content.normalized).to eq(normalized_value)
        expect(content).to be_valid
      end

      it "calls the normalize command" do
        described_class.initialize_with_normalizing_if_need(value, "")

        expect(Business::Dish::Word::Normalize::Command::NormalizeCommand)
          .to have_received(:call)
          .with(string_sequence: value)
      end
    end

    context "when normalized is nil" do
      it "normalizes the value" do
        content = described_class.initialize_with_normalizing_if_need(value, nil)

        expect(content.value).to eq(value)
        expect(content.normalized).to eq(normalized_value)
        expect(content).to be_valid
      end

      it "calls the normalize command" do
        described_class.initialize_with_normalizing_if_need(value, nil)

        expect(Business::Dish::Word::Normalize::Command::NormalizeCommand)
          .to have_received(:call)
          .with(string_sequence: value)
      end
    end
  end
end