main_tf = File.expand_path("../modules/alerts/main.tf", __dir__)
content = File.read(main_tf)

unsafe_pattern = "account_id = each.value.account_id == null ? data.aws_caller_identity.project.account_id : each.value.account_id"
matches = []
content.lines.each_with_index do |line, index|
  matches << index + 1 if line.include?(unsafe_pattern)
end

if matches.any?
  abort("metric_query.account_id must not default to aws_caller_identity in #{main_tf}:#{matches.join(",")}")
end

unless content.include?("account_id = each.value.account_id")
  abort("Expected metric_query.account_id to preserve explicit alert account_id values.")
end

puts "metric_query account_id handling ok"
