require 'rails_helper'
require_relative "../support/factories/user_repository"

RSpec.describe DishTag, type: :model do
  let(:user_record) { find_or_create_user }
  let(:dish_record) { FactoryBot.create(:dish, user: user_record) }

  describe "#persist_from_food_dish_root" do
    let(:content) { Business::Food::Dish::Tag::Content.new(value: "辛い料理", normalized: "辛い料理") }
    let(:tag_root) { Business::Food::Dish::Tag::Root.new(user_id: user_record.id, content: content) }

    context "with new dish tag record" do
      let(:dish_tag) { described_class.new(user: user_record, dish: dish_record) }

      it "persists the tag data from root" do
        dish_tag.persist_from_food_dish_root(tag_root)

        expect(dish_tag.content).to eq("辛い料理")
        expect(dish_tag.normalized_content).to eq("辛い料理")
        expect(dish_tag.persisted?).to be true
      end
    end

    context "with existing dish tag record" do
      let!(:existing_dish_tag) do
        described_class.create!(
          user: user_record,
          dish: dish_record,
          content: "甘い",
          normalized_content: "甘い"
        )
      end

      it "updates the existing tag data" do
        existing_dish_tag.persist_from_food_dish_root(tag_root)

        existing_dish_tag.reload
        expect(existing_dish_tag.content).to eq("辛い料理")
        expect(existing_dish_tag.normalized_content).to eq("辛い料理")
      end
    end
  end

  describe ".persist_from_root" do
    let(:content) { Business::Food::Dish::Tag::Content.new(value: "塩辛い", normalized: "塩辛い") }

    context "when root has id (existing tag)" do
      let!(:existing_tag) do
        described_class.create!(
          user: user_record,
          dish: dish_record,
          content: "元の内容",
          normalized_content: "元の内容"
        )
      end
      let(:tag_root) do
        Business::Food::Dish::Tag::Root.new(
          id: existing_tag.id,
          user_id: user_record.id,
          content: content
        )
      end

      it "updates existing tag record" do
        result = described_class.persist_from_root(tag_root, dish_record.id)

        expect(result).to eq(existing_tag)
        expect(result.content).to eq("塩辛い")
        expect(result.normalized_content).to eq("塩辛い")
      end
    end

    context "when root has no id (new tag)" do
      let(:tag_root) do
        Business::Food::Dish::Tag::Root.new(
          user_id: user_record.id,
          content: content
        )
      end

      it "creates new tag record" do
        result = described_class.persist_from_root(tag_root, dish_record.id)

        expect(result).to be_a(described_class)
        expect(result.persisted?).to be true
        expect(result.user_id).to eq(user_record.id)
        expect(result.dish_id).to eq(dish_record.id)
        expect(result.content).to eq("塩辛い")
        expect(result.normalized_content).to eq("塩辛い")
      end
    end
  end

  describe ".replace_tags_of_dish" do
    describe "料理に既存タグが無く1つ追加する場合" do
      let(:content) { Business::Food::Dish::Tag::Content.new(value: "新規タグ", normalized: "新規タグ") }
      let(:tag_root) { Business::Food::Dish::Tag::Root.new(user_id: user_record.id, content: content) }
      let(:tag_roots_for_replace) { [tag_root] }

      it "1つのタグが追加される" do
        result = described_class.replace_tags_of_dish(dish_record.id, tag_roots_for_replace)

        expect(result.count).to eq(1)
        created_tag = result.first
        expect(created_tag.content).to eq("新規タグ")
        expect(created_tag.normalized_content).to eq("新規タグ")
        expect(created_tag.dish_id).to eq(dish_record.id)
        expect(created_tag.user_id).to eq(user_record.id)
        expect(tag_root.id).to eq(created_tag.id)
      end
    end

    describe "料理に既存タグが無く複数追加する場合" do
      let(:content1) { Business::Food::Dish::Tag::Content.new(value: "新規タグ1", normalized: "新規タグ1") }
      let(:content2) { Business::Food::Dish::Tag::Content.new(value: "新規タグ2", normalized: "新規タグ2") }
      let(:tag_root1) { Business::Food::Dish::Tag::Root.new(user_id: user_record.id, content: content1) }
      let(:tag_root2) { Business::Food::Dish::Tag::Root.new(user_id: user_record.id, content: content2) }
      let(:tag_roots_for_replace) { [tag_root1, tag_root2] }

      it "複数のタグが追加される" do
        result = described_class.replace_tags_of_dish(dish_record.id, tag_roots_for_replace)

        expect(result.count).to eq(2)
        expect(result.map(&:content)).to contain_exactly("新規タグ1", "新規タグ2")
        expect(result.all? { |tag| tag.dish_id == dish_record.id }).to be true
        expect(result.all? { |tag| tag.user_id == user_record.id }).to be true
        expect(tag_root1.id).to be_present
        expect(tag_root2.id).to be_present
      end
    end

    describe "場合料理に既存タグがあり全て削除する場合" do
      let!(:existing_tag1) do
        described_class.create!(
          user: user_record,
          dish: dish_record,
          content: "既存タグ1",
          normalized_content: "既存タグ1"
        )
      end
      let!(:existing_tag2) do
        described_class.create!(
          user: user_record,
          dish: dish_record,
          content: "既存タグ2",
          normalized_content: "既存タグ2"
        )
      end
      let(:tag_roots_for_replace) { [] }

      it "全ての既存タグが削除される" do
        result = described_class.replace_tags_of_dish(dish_record.id, tag_roots_for_replace)

        expect(result.count).to eq(0)
        expect(described_class.where(dish_id: dish_record.id).count).to eq(0)
      end
    end

    describe "④料理に既存タグがあり、何も追加されなかった場合" do
      let!(:existing_tag1) do
        described_class.create!(
          user: user_record,
          dish: dish_record,
          content: "既存タグ1",
          normalized_content: "既存タグ1"
        )
      end
      let!(:existing_tag2) do
        described_class.create!(
          user: user_record,
          dish: dish_record,
          content: "既存タグ2",
          normalized_content: "既存タグ2"
        )
      end
      let(:content1) { Business::Food::Dish::Tag::Content.new(value: "既存タグ1", normalized: "既存タグ1") }
      let(:content2) { Business::Food::Dish::Tag::Content.new(value: "既存タグ2", normalized: "既存タグ2") }
      let(:tag_root1) { Business::Food::Dish::Tag::Root.new(id: existing_tag1.id, user_id: user_record.id, content: content1) }
      let(:tag_root2) { Business::Food::Dish::Tag::Root.new(id: existing_tag2.id, user_id: user_record.id, content: content2) }
      let(:tag_roots_for_replace) { [tag_root1, tag_root2] }

      it "何も変更されない" do
        initial_count = described_class.where(dish_id: dish_record.id).count
        result = described_class.replace_tags_of_dish(dish_record.id, tag_roots_for_replace)

        expect(result.count).to eq(initial_count)
        expect(result.map(&:id)).to contain_exactly(existing_tag1.id, existing_tag2.id)
        expect(described_class.find(existing_tag1.id)).to be_present
        expect(described_class.find(existing_tag2.id)).to be_present
      end
    end

    describe "料理に既存タグが2つあり、更新により1つはそのままで、1つ削除され、1つ追加される場合" do
      let!(:existing_tag1) do
        described_class.create!(
          user: user_record,
          dish: dish_record,
          content: "保持タグ",
          normalized_content: "保持タグ"
        )
      end
      let!(:existing_tag2) do
        described_class.create!(
          user: user_record,
          dish: dish_record,
          content: "削除タグ",
          normalized_content: "削除タグ"
        )
      end

      let(:keep_content) { Business::Food::Dish::Tag::Content.new(value: "保持タグ", normalized: "保持タグ") }
      let(:new_content) { Business::Food::Dish::Tag::Content.new(value: "新規タグ", normalized: "新規タグ") }
      let(:keep_tag_root) { Business::Food::Dish::Tag::Root.new(id: existing_tag1.id, user_id: user_record.id, content: keep_content) }
      let(:new_tag_root) { Business::Food::Dish::Tag::Root.new(user_id: user_record.id, content: new_content) }
      let(:tag_roots_for_replace) { [keep_tag_root, new_tag_root] }

      it "1つは維持、1つは削除、1つは追加される" do
        result = described_class.replace_tags_of_dish(dish_record.id, tag_roots_for_replace)

        expect(result.count).to eq(2)

        # 保持されたタグを確認
        expect(described_class.find_by(id: existing_tag1.id)).to be_present

        # 削除されたタグを確認
        expect(described_class.find_by(id: existing_tag2.id)).to be_nil

        # 新規追加されたタグを確認
        new_tag = result.find { |tag| tag.content == "新規タグ" }
        expect(new_tag).to be_present
        expect(new_tag.dish_id).to eq(dish_record.id)
        expect(new_tag.user_id).to eq(user_record.id)
        expect(new_tag_root.id).to eq(new_tag.id)
      end
    end
  end
end
