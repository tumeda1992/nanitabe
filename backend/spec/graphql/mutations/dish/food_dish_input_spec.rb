require "rails_helper"

RSpec.describe Mutations::Dish::FoodDishInput do
  describe ".source_relation" do
    it "keeps absent source or detail unassigned" do
      expect(described_class.source_relation(nil, double)).to be_nil
      expect(described_class.source_relation(double, nil)).to be_nil
    end

    [[1, 12, :book, { page: 12 }], [3, "https://example.test/recipe", :website, { url: "https://example.test/recipe" }], [50, "memo", :other, { memo: "memo" }]].each do |type, value, kind, detail|
      it "converts source type #{type} without changing the source ID" do
        source = Struct.new(:id, :type).new(42, type)
        input_detail = double(detail_value_of: value)
        result = described_class.source_relation(source, input_detail)
        expect(result.dish_source_id).to eq(42)
        expect(result.relation_kind).to eq(kind)
        expect(result.relation_detail).to eq(detail)
      end
    end

    it "uses the persisted ID for a newly created source" do
      source = Struct.new(:type).new(1)
      result = described_class.source_relation(source, double(detail_value_of: 8), source_id: 99)
      expect(result.dish_source_id).to eq(99)
    end
  end

  describe ".tags" do
    it "preserves nil and empty tags as an empty array" do
      expect(described_class.tags(nil)).to eq([])
      expect(described_class.tags([])).to eq([])
    end

    it "converts tags using the food module in input order" do
      first = double
      second = double
      expect(first).to receive(:convert_to_command_param).with(use_food_module: true).ordered.and_return(:first)
      expect(second).to receive(:convert_to_command_param).with(use_food_module: true).ordered.and_return(:second)
      expect(described_class.tags([first, second])).to eq([:first, :second])
    end
  end
end
