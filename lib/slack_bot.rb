Slack::RealTime::Client.config do |config|
  # Skip unread counts for each channel.
  config.start_options[:no_unreads] = true
  # Increase request timeout to 6 minutes.
  config.start_options[:request][:timeout] = 360
end

client = Slack::RealTime::Client.new(token: ENV['SLACK_BOT_TOKEN'])

client.on :message do |data|
  next if data.subtype
  pp data if Rails.env.development?

  channel = Channel.find_by(cid: data.channel)
  Message.create(user: data.user, text: data.text, channel: channel, raw: data.to_json)
end

client.start!
