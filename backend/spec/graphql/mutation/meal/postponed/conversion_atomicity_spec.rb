require "rails_helper"

RSpec.describe "Meal conversion atomicity" do
  let(:owner) { FactoryBot.create(:user, id_param: "conversion-owner") }
  let(:other) { FactoryBot.create(:user, id_param: "conversion-other") }
  let(:dish) { FactoryBot.create(:dish, user: owner) }

  %i[schedule postpone].each do |direction|
    context direction do
      let(:source) do
        if direction == :schedule
          PostponedMeal.create!(user: owner, dish: dish, meal_type: 3, comment: "引継ぎ")
        else
          Meal.create!(user: owner, dish: dish, meal_type: 3, comment: "引継ぎ", date: Date.new(2026, 11, 2))
        end
      end
      let(:destination) { direction == :schedule ? Meal : PostponedMeal }
      let(:resolver_class) { direction == :schedule ? Mutations::Meal::Postponed::SchedulePostponedMeal : Mutations::Meal::Postponed::PostponeMeal }
      let(:arguments) { direction == :schedule ? { postponed_meal_id: source.id, date: Date.new(2026, 11, 3) } : { meal_id: source.id } }

      def convert(actor_id = owner.id)
        context = GraphQL::Query.new(BackendSchema, "{ __typename }", context: { current_user_id: actor_id }).context
        resolver_class.new(object: nil, context: context, field: nil).resolve(**arguments)
      end

      it "rejects sequential reuse without creating a second destination" do
        convert
        expect { convert }.to raise_error(RuntimeError, /存在しません/)
        expect(destination.count).to eq(1)
      end

      it "rejects another owner without changing the source" do
        before = source.attributes
        expect { convert(other.id) }.to raise_error(RuntimeError, /存在しません/)
        expect(source.reload.attributes).to eq(before)
        expect(destination.count).to eq(0)
      end

      it "keeps the source if destination creation fails" do
        before = source.attributes
        command = direction == :schedule ? Business::Food::Meal::Usecase::AddCommand : Business::Food::Meal::Postponed::Usecase::AddCommand
        allow(command).to receive(:call).and_raise("destination failed")
        expect { convert }.to raise_error("destination failed")
        expect(source.reload.attributes).to eq(before)
        expect(destination.count).to eq(0)
      end

      it "rolls the destination and any frame release back if source deletion fails" do
        before = source.attributes
        entry = if direction == :postpone
                  frame = MealFrame.create!(user: owner, name: "保持する枠")
                  MealFrameEntry.create!(user: owner, meal_frame: frame, meal: source, date: source.date, meal_type: source.meal_type)
                end
        allow_any_instance_of(source.class).to receive(:destroy!).and_wrap_original do |original|
          original.call
          raise "deletion failed after write"
        end
        expect { convert }.to raise_error("deletion failed after write")
        expect(source.reload.attributes).to eq(before)
        expect(destination.count).to eq(0)
        expect(entry.reload.meal_id).to eq(source.id) if entry
      end
    end
  end

  it "rejects direct consumption of another owner's postponed meal" do
    source = PostponedMeal.create!(user: owner, dish: dish, meal_type: 3)
    expect {
      Business::Food::Meal::Postponed::Usecase::RemoveCommand.call(user_id: other.id, postponed_meal_id: source.id)
    }.to raise_error(RuntimeError, /存在しません/)
    expect(PostponedMeal.exists?(source.id)).to be(true)
  end
end
