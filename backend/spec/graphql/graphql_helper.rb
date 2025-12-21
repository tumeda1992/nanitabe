def fetch_mutation(mutation_string, variables, headers: {})
  post("/graphql", params: { query: mutation_string, variables: }, as: :json, headers:)

  begin
    response_body = JSON.parse(response.body)
  rescue JSON::ParserError => e
    # HTMLレスポンスなどJSONでないレスポンスの場合の処理
    raise "JSONパースエラー: #{e.message}" unless response.body.to_s.strip.start_with?("<!DOCTYPE", "<html")

    file_path = save_html_response_to_file(response.body)
    raise "JSONパースエラー: HTMLレスポンスが返されました。詳細は次のファイルを確認してください: #{file_path}\n#{e.message}"
  end

  if response_body["errors"]
    error_messages = response_body["errors"].map do |error|
      decorate_error_message(error["message"], build_error_detail_message(error))
    end
    raise decorate_error_messages(error_messages, variables)
  end

  response_body["data"]
end

def save_html_response_to_file(html_content)
  file_name = "html_response_#{Time.now.strftime("%Y%m%d%H%M%S")}.html"
  save_dir = Rails.root.join("tmp", "rspec_error_snapshot")
  file_path = save_dir.join(file_name)

  FileUtils.mkdir_p(save_dir)
  File.write(file_path, html_content)

  file_path.to_s
end

def build_error_detail_message(graphql_error)
  detail_messages = if graphql_error["extensions"].blank?
                      []
                    elsif graphql_error["extensions"]["detailed_errors"].present? # graphql-deviseエラー
                      graphql_error["extensions"]["detailed_errors"]
                    elsif graphql_error["extensions"]["problems"].present? # 通常のgraphqlエラー
                      graphql_error["extensions"]["problems"].map { |problem| problem["explanation"] }
                    else
                      []
                    end
  detail_messages.compact.join(" and ")
end

def decorate_error_message(summary, detail)
  message = summary
  if detail.present?
    message << "\n  #{detail}"
  end
  message
end

def decorate_error_messages(error_messages, variables)
  result = error_messages.join("\n")
  result << "\n\nvariables: #{variables}"
  result
end
