require "rails_helper"

RSpec.describe "Dish tag replacement" do
  let(:owner) { FactoryBot.create(:user, id_param: "replacement-owner") }
  let(:other) { FactoryBot.create(:user, id_param: "replacement-other") }
  let(:dish) { FactoryBot.create(:dish, user: owner, name: "元の料理") }
  let!(:tag) { FactoryBot.create(:dish_tag, user: owner, dish: dish, content: "alpha", normalized_content: "alpha") }

  def root_for(content, id: nil, user_id: owner.id)
    Business::Food::Dish::Tag::Root.new(
      id: id, user_id: user_id,
      content: Business::Food::Dish::Tag::Content.initialize_and_normalize(content)
    )
  end

  it "updates content and normalization without changing tag identity or ownership" do
    result = DishTag.replace_tags_of_dish(dish.id, [root_for("ぶた", id: tag.id)])
    expect(result).to be_a(ActiveRecord::Relation)
    expect(tag.reload.attributes.slice("id", "user_id", "dish_id", "content", "normalized_content")).to eq(
      "id" => tag.id, "user_id" => owner.id, "dish_id" => dish.id, "content" => "ぶた", "normalized_content" => "ブタ",
    )
    expect(result.pluck(:id)).to eq([tag.id])
  end

  it "updates retained tags while adding and deleting other tags" do
    removed = FactoryBot.create(:dish_tag, user: owner, dish: dish, content: "remove")
    added = root_for("追加")
    result = DishTag.replace_tags_of_dish(dish.id, [root_for("ぶた", id: tag.id), added])
    expect(result.pluck(:id)).to contain_exactly(tag.id, added.id)
    expect(tag.reload.content).to eq("ぶた")
    expect(DishTag.exists?(removed.id)).to be(false)
    expect(added.id).to be_present
  end

  %i[another_dish foreign_owner nonexistent].each do |kind|
    it "rejects #{kind} before applying any replacement" do
      invalid_id = case kind
                   when :another_dish
                     FactoryBot.create(:dish_tag, user: owner, dish: FactoryBot.create(:dish, user: owner)).id
                   when :foreign_owner
                     FactoryBot.create(:dish_tag, user: other, dish: FactoryBot.create(:dish, user: other)).id
                   else
                     DishTag.maximum(:id) + 1
                   end
      snapshot = DishTag.order(:id).map(&:attributes)
      added = root_for("追加")
      expect {
        DishTag.replace_tags_of_dish(dish.id, [added, root_for("変更", id: tag.id), root_for("不正", id: invalid_id)])
      }.to raise_error(ActiveRecord::RecordNotFound)
      expect(DishTag.order(:id).map(&:attributes)).to eq(snapshot)
      expect(added.id).to be_nil
    end
  end

  it "rejects a root whose owner differs from the dish owner" do
    snapshot = tag.attributes
    expect {
      DishTag.replace_tags_of_dish(dish.id, [root_for("不正", user_id: other.id)])
    }.to raise_error(ActiveRecord::RecordNotFound)
    expect(tag.reload.attributes).to eq(snapshot)
  end

  it "scopes direct persistence of an existing ID to its dish and owner" do
    other_dish = FactoryBot.create(:dish, user: owner)
    expect {
      DishTag.persist_from_root(root_for("不正", id: tag.id), other_dish.id)
    }.to raise_error(ActiveRecord::RecordNotFound)
    expect {
      DishTag.persist_from_root(root_for("不正", id: tag.id, user_id: other.id), dish.id)
    }.to raise_error(ActiveRecord::RecordNotFound)
    expect(tag.reload.content).to eq("alpha")
  end

  it "rolls replacement back when a later tag fails after an earlier insert" do
    first = root_for("先行")
    second = root_for("後続")
    snapshot = DishTag.order(:id).map(&:attributes)
    allow(DishTag).to receive(:persist_from_root).and_wrap_original do |original, root, dish_id|
      if root.equal?(second)
        expect(DishTag.where(dish_id: dish_id, content: "先行")).to exist
        raise "later tag failed"
      end
      original.call(root, dish_id)
    end
    expect { DishTag.replace_tags_of_dish(dish.id, [first, second]) }.to raise_error("later tag failed")
    expect(DishTag.order(:id).map(&:attributes)).to eq(snapshot)
  end

  it "rolls the dish, source relation and tags back on a later tag failure" do
    source = FactoryBot.create(:dish_source, user: owner)
    root = Dish.build_existing_root_from_id(dish.id)
    root.rename("保存途中の料理")
    root.attach_source(Business::Food::Dish::Source::Factory.build_existing_from_id(source.id),
                       Business::Food::Dish::Source::Locator::RecipeBook.new(42))
    first = root_for("先行")
    second = root_for("後続")
    root.replace_tags([first, second])
    snapshots = [dish.attributes, DishTag.order(:id).map(&:attributes), DishSourceRelation.all.map(&:attributes)]
    allow(DishTag).to receive(:persist_from_root).and_wrap_original do |original, tag_root, dish_id|
      if tag_root.equal?(second)
        expect(Dish.find(dish_id).name).to eq("保存途中の料理")
        expect(DishSourceRelation.where(dish_id: dish_id, dish_source_id: source.id)).to exist
        expect(DishTag.where(dish_id: dish_id, content: "先行")).to exist
        raise "later tag failed"
      end
      original.call(tag_root, dish_id)
    end
    expect { Dish.persist_from_food_dish_root(root) }.to raise_error("later tag failed")
    expect([dish.reload.attributes, DishTag.order(:id).map(&:attributes), DishSourceRelation.all.map(&:attributes)]).to eq(snapshots)
  end
end
