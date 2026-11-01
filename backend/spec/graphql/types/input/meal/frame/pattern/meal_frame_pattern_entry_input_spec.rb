require "rails_helper"

RSpec.describe Types::Input::Meal::Frame::Pattern::MealFramePatternEntryInput do
  it "transfers all command values to a separate symbol-keyed hash" do
    values = { day_offset: 2, meal_type: 3, meal_frame_id: 7 }
    input = described_class.new(nil, ruby_kwargs: values, context: nil, defaults_used: Set.new)

    expect(input.to_command_params).to eq(values)
    expect(input.to_command_params).not_to equal(input.to_command_params)
    expect(input.day_offset).to eq(2)
  end
end
