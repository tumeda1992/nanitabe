require 'rails_helper'

RSpec.describe Business::Food::Dish::Name, type: :model do
  describe 'validations' do
    context 'when value is present' do
      it 'is valid with value and normalized' do
        name = described_class.new(value: 'カレー', normalized: 'かれー')
        expect(name).to be_valid
      end
    end

    context 'when value is blank' do
      it 'is invalid' do
        expect {
          described_class.new(value: '', normalized: 'かれー')
        }.to raise_error(::Business::Base::Values::InvalidAttributeError, "Value can't be blank")
      end
    end

    context 'when normalized is blank' do
      it 'is invalid' do
        expect {
          described_class.new(value: 'カレー', normalized: '')
        }.to raise_error(::Business::Base::Values::InvalidAttributeError, "Normalized can't be blank")
      end
    end
  end

  describe '.initialize_and_normalize' do
    it 'creates instance with normalized value' do
      allow(::Business::Food::Dish::Word::Usecase::NormalizeCommand)
        .to receive(:call)
        .with(string_sequence: 'カレーライス')
        .and_return('かれーらいす')

      name = described_class.initialize_and_normalize('カレーライス')

      expect(name.value).to eq('カレーライス')
      expect(name.normalized).to eq('かれーらいす')
      expect(name).to be_valid
    end

    context 'when normalize command returns different value' do
      before do
        allow(::Business::Food::Dish::Word::Usecase::NormalizeCommand)
          .to receive(:call)
                .with(string_sequence: 'ハンバーグ')
                .and_return('はんばーぐ')
      end
      it 'uses the normalized result' do
        name = described_class.initialize_and_normalize('ハンバーグ')

        expect(name.value).to eq('ハンバーグ')
        expect(name.normalized).to eq('はんばーぐ')
      end
    end
  end

  describe '#initialize' do
    it 'can be initialized with attributes hash' do
      attributes = { value: 'パスタ', normalized: 'ぱすた' }
      name = described_class.new(attributes)

      expect(name.value).to eq('パスタ')
      expect(name.normalized).to eq('ぱすた')
    end

    it 'can be initialized without attributes' do
      expect {
        described_class.new
      }.to raise_error(::Business::Base::Values::InvalidAttributeError, "Value can't be blank, and Normalized can't be blank")
    end
  end
end
