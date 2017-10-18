module SlackClient
  module_function

  def build_api_client
    Slack::Web::Client.new(token: ENV['SLACK_API_TOKEN'])
  end

  def build_bot_client
    Slack::Web::Client.new(token: ENV['SLACK_BOT_TOKEN'])
  end
end
