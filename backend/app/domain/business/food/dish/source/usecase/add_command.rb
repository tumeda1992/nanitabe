module Business::Food::Dish::Source
  class Usecase::AddCommand < ::Business::Base::Command
    attribute :user_id, :integer
    validates :user_id, presence: true

    attribute :source_params, :command_params
    validates :source_params, presence: true
    validate :validate_source, if: -> { source_params.present? }

    def call
      source_root = Business::Food::Dish::Source::Factory.build(
        user_id,
        source_params.name,
        source_params.type,
        comment: source_params.comment
      )
      source_record = ::DishSource.build_from_food_dish_source_root(source_root)
      source_record.save!
      source_root.set_id(source_record.id)

      source_root
    end

    private

    def validate_source
      return if source_params.valid_for_create?

      errors.add(:source_params, source_params.errors.full_messages.join(', '))
    end
  end
end