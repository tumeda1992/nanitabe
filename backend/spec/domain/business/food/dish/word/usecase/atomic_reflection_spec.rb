require "rails_helper"

RSpec.describe "Atomic dictionary changes and reflection" do
  let(:user) { FactoryBot.create(:user, id_param: "fr024-owner") }
  let!(:first) { Dish.create!(user: user, name: "FR024X1", normalized_name: "stored first", meal_position: 1) }
  let!(:second) { Dish.create!(user: user, name: "FR024X2", normalized_name: "stored second", meal_position: 1) }
  let!(:tags) do
    [first, second].map { |dish| DishTag.create!(user: user, dish: dish, content: "FR024Xtag", normalized_content: "stored tag") }
  end

  [:add, :update, :remove, :reflect].each do |operation|
    it "rolls back #{operation} and all prior dish/tag writes after a later persistence failure" do
      word = unless operation == :add
               NormalizeWord.create!(entered_source: "FR024X", source: "FR024X", entered_destination: "before", destination: "before")
             end
      word_rows = NormalizeWord.order(:id).map(&:attributes)
      dish_rows = [first, second].map(&:attributes)
      tag_rows = tags.map(&:attributes)
      observed = []
      allow(Dish).to receive(:persist_from_food_dish_root).and_wrap_original do |original, root|
        if root.id == second.id
          observed << [first.reload.normalized_name, tags.first.reload.normalized_content]
          raise "late persistence failure"
        end
        original.call(root)
      end

      expect do
        case operation
        when :add
          Business::Food::Dish::Word::Usecase::AddCommand.call(source: "FR024X", destination: "after")
        when :update
          Business::Food::Dish::Word::Usecase::UpdateCommand.call(normalize_word_id: word.id, source: "FR024X", destination: "after")
        when :remove
          Business::Food::Dish::Word::Usecase::RemoveCommand.call(normalize_word_id: word.id)
        when :reflect
          Business::Food::Dish::Word::Usecase::ReflectLatestNormalizeWordCommand.call
        end
      end.to raise_error(Business::Food::Dish::Word::Errors::ReflectLatestNormalizeWordError, /late persistence failure/)

      expect(observed.size).to eq(1)
      expect(observed.first[0]).not_to eq("stored first")
      expect(observed.first[1]).not_to eq("stored tag")
      expect(NormalizeWord.order(:id).map(&:attributes)).to eq(word_rows)
      expect([first, second].map { |dish| dish.reload.attributes }).to eq(dish_rows)
      expect(tags.map { |tag| tag.reload.attributes }).to eq(tag_rows)
    end
  end
end
