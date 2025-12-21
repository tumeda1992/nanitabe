require "rails_helper"

RSpec.describe Business::Food::Dish::Usecase::Params::Dish do
  describe "validations" do
    context "on :create" do
      context "with valid parameters" do
        let(:params) do
          {
            name: "test_dish",
            meal_position: 1,
            comment: "test_comment",
          }
        end

        it "creates instance successfully" do
          dish_params = described_class.new(:create, **params)

          expect(dish_params.name).to eq("test_dish")
          expect(dish_params.meal_position).to eq(1)
          expect(dish_params.comment).to eq("test_comment")
          expect(dish_params.id).to be_nil
        end
      end

      context "when id is present" do
        let(:params) do
          {
            id: 1,
            name: "test_dish",
            meal_position: 1,
          }
        end

        it "raises validation error" do
          expect { described_class.new(:create, **params) }.to raise_error(/Id must be blank/)
        end
      end

      context "when name is missing" do
        let(:params) do
          {
            meal_position: 1,
          }
        end

        it "raises validation error" do
          expect { described_class.new(:create, **params) }.to raise_error(/Name can't be blank/)
        end
      end

      context "when meal_position is missing" do
        let(:params) do
          {
            name: "test_dish",
          }
        end

        it "raises validation error" do
          expect { described_class.new(:create, **params) }.to raise_error(/Meal position can't be blank/)
        end
      end
    end

    context "on :update" do
      context "with valid parameters" do
        let(:params) do
          {
            id: 1,
            name: "updated_dish",
            meal_position: 2,
            comment: "updated_comment",
          }
        end

        it "creates instance successfully" do
          dish_params = described_class.new(:update, **params)

          expect(dish_params.id).to eq(1)
          expect(dish_params.name).to eq("updated_dish")
          expect(dish_params.meal_position).to eq(2)
          expect(dish_params.comment).to eq("updated_comment")
        end
      end

      context "when id is missing" do
        let(:params) do
          {
            name: "updated_dish",
            meal_position: 2,
          }
        end

        it "raises validation error" do
          expect { described_class.new(:update, **params) }.to raise_error(/Id can't be blank/)
        end
      end

      context "when name is missing" do
        let(:params) do
          {
            id: 1,
            meal_position: 2,
          }
        end

        it "creates instance successfully (name is optional on update)" do
          dish_params = described_class.new(:update, **params)

          expect(dish_params.id).to eq(1)
          expect(dish_params.meal_position).to eq(2)
          expect(dish_params.name).to be_nil
        end
      end

      context "when meal_position is missing" do
        let(:params) do
          {
            id: 1,
            name: "updated_dish",
          }
        end

        it "creates instance successfully (meal_position is optional on update)" do
          dish_params = described_class.new(:update, **params)

          expect(dish_params.id).to eq(1)
          expect(dish_params.name).to eq("updated_dish")
          expect(dish_params.meal_position).to be_nil
        end
      end
    end
  end

  describe "attributes" do
    let(:params) do
      {
        id: 1,
        name: "test_dish",
        meal_position: 1,
        comment: "test_comment",
      }
    end

    subject { described_class.new(**params) }

    it "responds to all expected methods" do
      expect(subject).to respond_to(:id, :name, :meal_position, :comment)
    end

    it "stores attribute values correctly" do
      expect(subject.id).to eq(1)
      expect(subject.name).to eq("test_dish")
      expect(subject.meal_position).to eq(1)
      expect(subject.comment).to eq("test_comment")
    end
  end
end
