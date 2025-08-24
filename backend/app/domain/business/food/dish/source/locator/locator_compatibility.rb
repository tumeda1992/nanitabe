module Business::Food::Dish::Source::Locator::LocatorCompatibility
  module_function
  def supports?(source_type, kind)
    return false if kind.nil?
    case kind.to_sym
    when :book
      source_type == Business::Food::Dish::Source::Type::RECIPE_BOOK
    when :website
      [Business::Food::Dish::Source::Type::YOUTUBE,
       Business::Food::Dish::Source::Type::WEBSITE].include?(source_type)
    when :other
      Business::Food::Dish::Source::Type::TYPES.include?(source_type)
    else
      false
    end
  end
end
