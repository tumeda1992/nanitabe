module Business::Food::Dish::Tag
  class Root < ::Business::Base::Entity
    attribute :id, :integer

    attribute :user_id, :integer
    validates :user_id, presence: true

    attribute :content, :any
    validates :content, presence: true

    def set_id(new_id)
      raise "新規作成時以外idを変更できません" if id.present?

      self.id = new_id
    end

    def renormalize_content
      self.content = Content.initialize_and_normalize(content.value)
    end
  end
end
