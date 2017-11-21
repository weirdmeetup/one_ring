# frozen_string_literal: true

module SlackClient
  module_function

  def api_client
    @api_client ||= Slack::Web::Client.new(token: ENV["SLACK_API_TOKEN"])
  end
  private_class_method :api_client

  def post_msg_via_api(args)
    api_client.chat_postMessage(args)
  end

  %w[
    channels_create channels_invite
    channels_archive channels_unarchive
    channels_join channels_leave
    channels_history
    users_info
  ].each do |method_name|
    define_method(method_name) do |*args|
      api_client.send(method_name, *args)
    end
  end

  def bot_client
    @bot_client ||= Slack::Web::Client.new(token: ENV["SLACK_BOT_TOKEN"])
  end
  private_class_method :bot_client

  def post_msg_as_bot(args)
    bot_client.chat_postMessage(args)
  end

  def bot_uid
    bot_client.auth_test.user_id
  end

  %w[channels_info channels_list].each do |method_name|
    define_method(method_name) do |*args|
      bot_client.send(method_name, *args)
    end
  end

  def manage_client
    @manage_client ||= Slack::Web::Client.new(token: ENV["MANAGE_API_TOKEN"])
  end
  private_class_method :manage_client

  def post_msg_to_manager(text)
    manage_client.chat_postMessage(channel: "#" + ENV["MANAGE_CHANNEL"], text: text, as_user: true)
  end
end
