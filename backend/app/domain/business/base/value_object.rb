require_relative './values'

# config/initializers/types.rb のActiveModelのタイプ定義ファイルで読めるようにネスト形式に
module Business
  module Base
    class ValueObject < Values
    end
  end
end
