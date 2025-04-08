require 'net/http'

module Blazer
  class SlackNotifier
    def self.state_change(check, state, state_was, result_rows_size, message, check_type)
      return unless check.notify_slack
      
      # Use default channel instead of reading from check
      channel = Blazer.default_slack_channel
      
      icon = state == 'passing' ? ':white_check_mark:' : ':bangbang:'
      message = "#{icon} `#{check.query.name}` check changed status from `#{state_was}` to `#{state}`. It now returns `#{result_rows_size}` rows."
      notify_slack(message, channel)
    end

    def self.notify_count_change(check, state, rows_before, rows_after)
      direction = rows_before - rows_after > 0 ? "#{rows_before - rows_after} less" : "#{rows_after - rows_before} more"
      message = ":thinking_face: `#{check.query.name}` changed row count. It now returns `#{direction}` rows (from `#{rows_before}` to `#{rows_after}`)."
      notify_slack(message)
    end

    def self.failing_checks(checks)
      return if checks.empty?
      
      # Use default channel for all notifications
      channel = Blazer.default_slack_channel
      
      message = "Checks failing.\n"
      checks.each { |c| message << "#{c.query.name} (#{c.state})\n" }
      notify_slack(message, channel)
    end

    def self.notify_slack(message, channel = nil)
      slack_url = ENV.fetch('SLACK_WEBHOOK_URL')

      params = {
        text: message
      }

      uri = URI.parse(slack_url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      request = Net::HTTP::Post.new(uri.request_uri)
      request.body = params.to_json
      http.request(request)
    end
  end
end
