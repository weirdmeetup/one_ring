# frozen_string_literal: true

class ArchivingJob < ApplicationJob
  queue_as :default

  def perform(*_args)
    affected_channels = []
    Channel.find_each do |channel|
      next unless channel.inactive_candidate?

      begin
        channel.archive
        affected_channels.push(channel)
      rescue => e
        SlackClient.post_msg_to_manager(build_error_message(channel, e))
        raise e
      end
    end
    SlackClient.post_msg_to_manager(build_message(affected_channels))
    if affected_channels.size > 0
      SlackClient.post_msg_via_api(channel: ENV["NOTICE_CHANNEL"], text: build_message_for_public(affected_channels))
    end
  end

  private

  def build_error_message(channel, e)
    message = <<~EOS
      There was some problem on 'WarningJob' execution:
      Channel which raised error is #{channel.name}(#{channel.cid}).
      Error Message: #{e.message}
      Backtrace:
      #{e.backtrace.join("\n")}
    EOS
  end

  def build_message(channels)
    if !channels.empty?
      message = <<~EOS
        WarningJob performed result:
        Affected Channel(#{channels.size}) => #{channels.map(&:name).join(', ')}
      EOS
    else
      "ArchivingJob performed result: no affected channel"
    end
  end

  def build_message_for_public(channels)
    names = channels.map { |channel| "##{channel.name}" }.join(', ')
    "Channel RIP: #{names}"
  end
end
