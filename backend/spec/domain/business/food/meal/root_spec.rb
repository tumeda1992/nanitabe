require "rails_helper"
require_relative "../../../../support/factories/user_repository"
require_relative "../../../../support/factories/dish_repository"

RSpec.describe Business::Food::Meal::Root do
  let(:user_record) { find_or_create_user }
  let(:dish_record) { find_or_create_dish }

  let(:valid_attributes) do
    {
      user_id: user_record.id,
      dish_id: dish_record.id,
      date: Date.today,
      meal_type: 1,
      comment: "test comment",
    }
  end

  describe "validations" do
    it "is valid with valid attributes" do
      root = described_class.new(valid_attributes)
      expect(root).to be_valid
    end

    it "requires user_id" do
      expect {
        described_class.new(valid_attributes.except(:user_id))
      }.to raise_error(Business::Base::Values::InvalidAttributeError, /User can't be blank/)
    end

    it "requires dish_id" do
      expect {
        described_class.new(valid_attributes.except(:dish_id))
      }.to raise_error(Business::Base::Values::InvalidAttributeError, /Dish can't be blank/)
    end

    it "requires date" do
      expect {
        described_class.new(valid_attributes.except(:date))
      }.to raise_error(Business::Base::Values::InvalidAttributeError, /Date can't be blank/)
    end

    it "requires meal_type" do
      expect {
        described_class.new(valid_attributes.except(:meal_type))
      }.to raise_error(Business::Base::Values::InvalidAttributeError, /Meal type can't be blank/)
    end

    it "allows blank comment" do
      root = described_class.new(valid_attributes.except(:comment))
      expect(root).to be_valid
    end
  end

  describe "#set_id" do
    let(:root) { described_class.new(valid_attributes) }

    context "when id is not present" do
      it "sets the id" do
        root.set_id(123)
        expect(root.id).to eq(123)
      end
    end

    context "when id is already present" do
      before { root.id = 456 }

      it "raises error" do
        expect {
          root.set_id(789)
        }.to raise_error("新規作成時以外idを変更できません")
      end
    end
  end

  describe "#assign_dish" do
    let(:root) { described_class.new(valid_attributes) }
    let(:new_dish_record) { FactoryBot.create(:dish, user: user_record) }

    context "with valid dish_id" do
      it "assigns the dish_id" do
        root.assign_dish(new_dish_record.id)
        expect(root.dish_id).to eq(new_dish_record.id)
      end
    end

    context "with invalid dish_id" do
      it "raises error" do
        expect {
          root.assign_dish(999_999)
        }.to raise_error("存在しない料理を紐付けることはできません。")
      end
    end
  end

  describe "#reschedule" do
    let(:root) { described_class.new(valid_attributes) }
    let(:new_date) { Date.tomorrow }

    context "with valid date" do
      it "updates the date" do
        root.reschedule(new_date)
        expect(root.date).to eq(new_date)
      end
    end

    context "with blank date" do
      it "raises error" do
        expect {
          root.reschedule(nil)
        }.to raise_error("日付は空にできません。")
      end
    end
  end

  describe "#switch_meal_type" do
    let(:root) { described_class.new(valid_attributes) }
    let(:new_meal_type) { 2 }

    context "with valid meal_type" do
      it "updates the meal_type" do
        root.switch_meal_type(new_meal_type)
        expect(root.meal_type).to eq(new_meal_type)
      end
    end

    context "with blank meal_type" do
      it "raises error" do
        expect {
          root.switch_meal_type(nil)
        }.to raise_error("食事の種類は空にできません。")
      end
    end
  end

  describe "#revise_comment" do
    let(:root) { described_class.new(valid_attributes) }
    let(:new_comment) { "updated comment" }

    it "updates the comment" do
      root.revise_comment(new_comment)
      expect(root.comment).to eq(new_comment)
    end

    it "allows blank comment" do
      root.revise_comment("")
      expect(root.comment).to eq("")
    end

    it "allows nil comment" do
      root.revise_comment(nil)
      expect(root.comment).to be_nil
    end
  end
end
