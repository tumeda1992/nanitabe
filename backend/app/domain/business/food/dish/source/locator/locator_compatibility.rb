module Business::Food::Dish::Source::Locator::LocatorCompatibility
  module_function
  def supports?(source_type, kind)
    return false if kind.nil?

    source_type_value = source_type.value
    case kind.to_sym
    when :book
      source_type_value == Business::Food::Dish::Source::Type::RECIPE_BOOK
    when :website
      [Business::Food::Dish::Source::Type::YOUTUBE,
       Business::Food::Dish::Source::Type::WEBSITE].include?(source_type_value)
    when :other
      Business::Food::Dish::Source::Type::TYPES.include?(source_type_value)
    else
      false
    end
  end
end
