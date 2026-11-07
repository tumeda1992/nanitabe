require "rails_helper"

RSpec.shared_context "dictionary reflection failure" do
  let(:user) { FactoryBot.create(:user, id_param: "fr024-owner") }
  let(:first_dish) { Dish.create!(user: user, name: "FR024X1", normalized_name: "stored first", meal_position: 1) }
  let(:second_dish) { Dish.create!(user: user, name: "FR024X2", normalized_name: "stored second", meal_position: 1) }
  let(:first_tag) { DishTag.create!(user: user, dish: first_dish, content: "FR024Xtag", normalized_content: "stored tag") }
  let(:second_tag) { DishTag.create!(user: user, dish: second_dish, content: "FR024Xtag", normalized_content: "stored tag") }
  let(:observations) { [] }
  let(:word_rows_before) { NormalizeWord.order(:id).map(&:attributes) }
  let(:first_dish_before) { first_dish.attributes }
  let(:second_dish_before) { second_dish.attributes }
  let(:first_tag_before) { first_tag.attributes }
  let(:second_tag_before) { second_tag.attributes }

  before do
    dictionary_fixture
    first_tag
    second_tag
    word_rows_before
    first_dish_before
    second_dish_before
    first_tag_before
    second_tag_before
    allow(Dish).to receive(:persist_from_food_dish_root).and_wrap_original do |original, root|
      if root.id == second_dish.id
        observations << { first_dish_name: first_dish.reload.normalized_name, first_tag_content: first_tag.reload.normalized_content }
        raise "late persistence failure"
      end
      original.call(root)
    end
  end
end

RSpec.shared_examples "atomic dictionary reflection" do
  it "rolls back the dictionary, dishes and tags after a later persistence failure" do
    expect { subject }.to raise_error(Business::Food::Dish::Word::Errors::ReflectLatestNormalizeWordError, /late persistence failure/)

    aggregate_failures "先行保存の観測" do
      expect(observations.size).to eq(1)
      expect(observations.sole.fetch(:first_dish_name)).not_to eq(first_dish_before.fetch("normalized_name"))
      expect(observations.sole.fetch(:first_tag_content)).not_to eq(first_tag_before.fetch("normalized_content"))
    end
    aggregate_failures "辞書のrollback" do
      expect(NormalizeWord.order(:id).map(&:attributes)).to eq(word_rows_before)
    end
    aggregate_failures "料理のrollback" do
      expect(first_dish.reload.attributes).to eq(first_dish_before)
      expect(second_dish.reload.attributes).to eq(second_dish_before)
    end
    aggregate_failures "タグのrollback" do
      expect(first_tag.reload.attributes).to eq(first_tag_before)
      expect(second_tag.reload.attributes).to eq(second_tag_before)
    end
  end
end

RSpec.describe Business::Food::Dish::Word::Usecase::AddCommand do
  include_context "dictionary reflection failure"
  let(:dictionary_fixture) { nil }
  subject { described_class.call(source: "FR024X", destination: "after") }
  include_examples "atomic dictionary reflection"
end

RSpec.describe Business::Food::Dish::Word::Usecase::UpdateCommand do
  include_context "dictionary reflection failure"
  let(:dictionary_fixture) { NormalizeWord.create!(entered_source: "FR024X", source: "FR024X", entered_destination: "before", destination: "before") }
  subject { described_class.call(normalize_word_id: dictionary_fixture.id, source: "FR024X", destination: "after") }
  include_examples "atomic dictionary reflection"
end

RSpec.describe Business::Food::Dish::Word::Usecase::RemoveCommand do
  include_context "dictionary reflection failure"
  let(:dictionary_fixture) { NormalizeWord.create!(entered_source: "FR024X", source: "FR024X", entered_destination: "before", destination: "before") }
  subject { described_class.call(normalize_word_id: dictionary_fixture.id) }
  include_examples "atomic dictionary reflection"
end

RSpec.describe Business::Food::Dish::Word::Usecase::ReflectLatestNormalizeWordCommand do
  include_context "dictionary reflection failure"
  let(:dictionary_fixture) { NormalizeWord.create!(entered_source: "FR024X", source: "FR024X", entered_destination: "before", destination: "before") }
  subject { described_class.call }
  include_examples "atomic dictionary reflection"
end
