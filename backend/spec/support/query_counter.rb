# クエリ数をカウントするヘルパー
# Bulletが検出できないN+1問題を検出するために使用
module QueryCounter
  def count_queries(&block)
    queries = []
    counter = ->(name, started, finished, unique_id, payload) {
      # SCHEMA、CACHE、トランザクション関連のクエリは除外
      unless payload[:name] =~ /SCHEMA|CACHE/ || payload[:sql] =~ /^(BEGIN|COMMIT|SAVEPOINT|RELEASE)/
        queries << payload[:sql]
      end
    }

    ActiveSupport::Notifications.subscribed(counter, "sql.active_record", &block)

    queries
  end

  def expect_query_count(expected_count, &block)
    queries = count_queries(&block)
    actual_count = queries.size

    if actual_count != expected_count
      puts "\n期待クエリ数: #{expected_count}"
      puts "実際クエリ数: #{actual_count}"
      puts "\n実行されたクエリ:"
      queries.each_with_index do |query, index|
        puts "#{index + 1}. #{query}"
      end
    end

    expect(actual_count).to eq(expected_count), "期待クエリ数: #{expected_count}, 実際: #{actual_count}"
  end
end

RSpec.configure do |config|
  config.include QueryCounter
end
