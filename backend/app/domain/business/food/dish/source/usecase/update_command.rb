module Business::Food::Dish::Source
  class Usecase::UpdateCommand < ::Business::Base::Command
    attribute :user_id, :integer
    validates :user_id, presence: true

    attribute :source_params, :command_params
    validates :source_params, presence: true
    validate :validate_source, if: -> { source_params.present? }

    def call
      source_root = Business::Food::Dish::Source::Factory.build_existing_from_id(source_params.id)
      raise "指定したレシピ元は存在しません。" if source_root.blank?

      updated_source_root = update_source_root(source_root, source_params)

      updated_source_root
    end

    private

    def validate_source
      return if source_params.valid_for_update?

      errors.add(:source_params, source_params.errors.full_messages.join(', '))
    end

    def update_source_root(source_root, source_params)
      source_root.rename(source_params.name) if source_params.name.present?
      source_root.change_type(source_params.type) if source_params.type.present?
      source_root.revise_comment(source_params.comment) unless source_params.comment.nil?

      source_root.validate!

      source_record = ::DishSource.find(source_root.id)
      update_attributes = {}
      update_attributes[:name] = source_root.name if source_params.name.present?
      update_attributes[:type] = source_root.type.value if source_params.type.present?
      update_attributes[:comment] = source_root.comment unless source_params.comment.nil?

      source_record.update!(update_attributes)

      source_root
    end
  end
end