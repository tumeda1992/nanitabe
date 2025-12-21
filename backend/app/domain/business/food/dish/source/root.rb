module Business::Food::Dish::Source
  class Root < ::Business::Base::Entity
    attribute :id, :integer

    attribute :user_id, :integer
    validates :user_id, presence: true

    attribute :name, :string
    validates :name, presence: true

    attribute :type, :dish_source_type
    validates :type, presence: true

    attribute :comment, :string

    def set_id(new_id)
      raise "新規作成時以外idを変更できません" if id.present?

      self.id = new_id
    end

    def rename(new_name)
      raise "レシピ元名は空にできません。" if new_name.blank?

      self.name = new_name
    end

    def change_type(new_type)
      raise "レシピ元の種別は空にできません。" if new_type.blank?

      self.type = new_type.is_a?(Business::Food::Dish::Source::Type) ? new_type.value : new_type
    end

    def revise_comment(new_comment)
      self.comment = new_comment
    end
  end
end
