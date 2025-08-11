module Business::Food::Dish
  class Root < ::Business::Base::Entity
    attribute :id, :integer

    attribute :user_id, :integer
    validates :user_id, presence: true

    attribute :name, :string
    validates :name, presence: true

    attribute :normalized_name, :string

    attribute :meal_position, :integer
    validates :meal_position, presence: true

    attribute :comment, :string

    def rename(new_name)
      raise "料理名は空にできません。" if new_name.blank?

      self.name = new_name
      self.normalized_name = ::Business::Dish::Word::Normalize::Command::NormalizeCommand.call(string_sequence: new_name)
    end

    def reposition_in_meal(new_meal_position)
      raise "料理の位置は空にできません。" if new_meal_position.blank?

      self.meal_position = new_meal_position
    end

    def revice_comment(new_comment)
      self.comment = new_comment
    end
  end
end
