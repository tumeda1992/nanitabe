require "rails_helper"

RSpec.shared_examples "literal dictionary normalization" do
  def word(source, destination)
    NormalizeWord.create!(entered_source: source, entered_destination: destination, source: source, destination: destination)
  end

  ["[", ".", "*", "\\", "%", "_"].each do |source|
    it "treats source #{source.inspect} as a literal string" do
      word(source, "置換")
      expect(described_class.call(string_sequence: "head#{source}tail#{source}")).to eq("head置換tail置換")
      expect(described_class.call(string_sequence: "unrelated")).to eq("unrelated")
    end
  end

  it "does not interpret replacement backreferences" do
    destination = "\\1|\\&|\\`|\\'"
    word("TOKEN", destination)
    expect(described_class.call(string_sequence: "TOKEN TOKEN")).to eq("#{destination} #{destination}")
  end

  ["%", "_", "C"].each do |introduced_source|
    it "does not introduce a rule matching only replacement output #{introduced_source}" do
      word("A", introduced_source)
      word(introduced_source, "changed again")
      expect(described_class.call(string_sequence: "A")).to eq(introduced_source)
    end
  end
end

RSpec.describe Business::Food::Dish::Word::Usecase::Normalizer do
  include_examples "literal dictionary normalization"

  it "reflects literal replacements into dish and tag normalized values" do
    user = FactoryBot.create(:user, id_param: "fr023-owner")
    dish = FactoryBot.create(:dish, user: user, name: "A[B", normalized_name: "old name")
    tag = DishTag.create!(user: user, dish: dish, content: "C[D", normalized_content: "old tag")
    word("[", "記号")
    Business::Food::Dish::Word::Usecase::ReflectLatestNormalizeWordCommand.call
    expect(dish.reload.normalized_name).to eq("A記号B")
    expect(tag.reload.normalized_content).to eq("C記号D")
    expect(dish.name).to eq("A[B")
    expect(tag.content).to eq("C[D")
  end
end

RSpec.describe Business::Dish::Word::Normalize::Command::NormalizeCommand do
  it_behaves_like "literal dictionary normalization"
end
