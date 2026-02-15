module Types::Input::Dish::Word
  class WordForCreate < ::Types::BaseInputObject
    argument :source, String, required: true
    argument :destination, String, required: false
  end
end
