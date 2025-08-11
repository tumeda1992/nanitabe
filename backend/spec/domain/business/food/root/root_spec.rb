require "rails_helper"

RSpec.describe Business::Food::Dish::Root, type: :model do
  let(:user_id) { 1 }
  let(:dish_name) { "test_dish" }
  let(:meal_position) { 1 }
  let(:comment) { "test_comment" }

  subject { Business::Food::Dish::Root.new(user_id: user_id, name: dish_name, meal_position: meal_position, comment: comment) }

  describe "validations" do
    it { should validate_presence_of(:user_id) }
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:meal_position) }
  end

  describe "#set_id" do
    let(:new_id) { 123 }

    context "when id is not present" do
      it "sets id successfully" do
        subject.set_id(new_id)

        expect(subject.id).to eq(new_id)
      end
    end

    context "when id is already present" do
      before { subject.id = 456 }

      it "raises error" do
        expect { subject.set_id(new_id) }.to raise_error("新規作成時以外idを変更できません")
      end
    end
  end

  describe "#rename" do
    let(:new_name) { "new_dish_name" }
    let(:normalized_new_name) { "new_dish_name_normalized" }

    before do
      allow(::Business::Dish::Word::Normalize::Command::NormalizeCommand)
        .to receive(:call)
        .with(string_sequence: new_name)
        .and_return(normalized_new_name)
    end

    it "updates name and normalized_name" do
      subject.rename(new_name)

      expect(subject.name).to eq(new_name)
      expect(subject.normalized_name).to eq(normalized_new_name)
    end

    context "when new_name is blank" do
      it "raises error" do
        expect { subject.rename("") }.to raise_error("料理名は空にできません。")
        expect { subject.rename(nil) }.to raise_error("料理名は空にできません。")
      end
    end
  end

  describe "#reposition_in_meal" do
    let(:new_meal_position) { 2 }

    it "updates meal_position" do
      subject.reposition_in_meal(new_meal_position)

      expect(subject.meal_position).to eq(new_meal_position)
    end

    context "when new_meal_position is blank" do
      it "raises error" do
        expect { subject.reposition_in_meal("") }.to raise_error("料理の位置は空にできません。")
        expect { subject.reposition_in_meal(nil) }.to raise_error("料理の位置は空にできません。")
      end
    end
  end

  describe "#revice_comment" do
    let(:new_comment) { "new_comment" }

    it "updates comment" do
      subject.revise_comment(new_comment)

      expect(subject.comment).to eq(new_comment)
    end

    it "allows blank comment" do
      subject.revise_comment("")
      expect(subject.comment).to eq("")

      subject.revise_comment(nil)
      expect(subject.comment).to be_nil
    end
  end
end
