module Business::Food::Meal::Frame
  class Root < ::Business::Base::Entity
    attribute :id, :integer

    attribute :user_id, :integer
    validates :user_id, presence: true

    attribute :name, :string
    validates :name, presence: true

    def set_id(new_id)
      raise "新規作成時以外idを変更できません" if id.present?

      self.id = new_id
    end

    def rename(new_name)
      raise "枠名は空にできません。" if new_name.blank?

      self.name = new_name
    end
  end
end
