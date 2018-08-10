# frozen_string_literal: true

class SyncMessagesJob < ApplicationJob
  queue_as :default

  def perform(*_args)
    Channel.alive.each do |channel|
      sync_messages(channel)
    end
  rescue => e
    SlackClient.post_msg_to_manager(build_error_message(channel, e))
    raise e
  end

  private

  def sync_messages(channel)
    messages =
      fecth_messages(channel)
      .reject(&:subtype)
      .map { |m| build_message(channel, m) }
    Message.import(messages)
  end

  def fecth_messages(channel)
    last_message = channel.last_message
    oldest = last_message ? JSON.parse(last_message.raw).fetch("ts") : 0
    latest = Time.now.to_i
    all_messages = []
    loop do
      res = SlackClient.channels_history(
        channel: channel.cid,
        count: 1000,
        oldest: oldest,
        latest: latest
      )
      all_messages.concat(res.messages)
      break unless res.has_more
      latest = res.messages.last.ts
    end
    all_messages
  end

  def build_message(channel, data)
    Message.new(user: data.user, text: data.text, channel: channel, created_at: Time.zone.at(data.ts.to_f), raw: data.to_json)
  end

  def build_error_message(channel, e)
    message = <<~EOS
      There was some problem on 'ArchivingJob' execution:
      Channel which raised error is #{channel.name}(#{channel.cid}).
      Error Message: #{e.message}
      Backtrace:
      #{e.backtrace.join("\n")}
    EOS
  end
end
