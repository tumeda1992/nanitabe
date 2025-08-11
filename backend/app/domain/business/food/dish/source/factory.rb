module Business::Food::Dish::Source
  class Factory
    class << self
      def build(user_id, name, type, comment: nil)
        source = Business::Food::Dish::Source::Root.new(
          user_id: user_id,
          name: name,
          type: type.is_a?(Business::Food::Dish::Source::Type) ? type.value : type,
          comment: comment
        )
        source.validate!
        source
      end

      def build_existing_from_id(source_id)
        source_record = ::DishSource.find_by(id: source_id)
        return if source_record.blank?

        build_existing_from_params(source_record.attributes)
      end

      private

      def build_existing_from_params(source_params)
        Business::Food::Dish::Source::Root.new(
          id: source_params["id"],
          user_id: source_params["user_id"],
          name: source_params["name"],
          type: source_params["type"],
          comment: source_params["comment"]
        )
      end
    end
  end
end