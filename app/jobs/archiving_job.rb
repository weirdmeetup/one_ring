# frozen_string_literal: true

class ArchivingJob < ApplicationJob
  queue_as :default

  def perform(*_args)
    affected_channels = []
    affected_channels_tomorrow = []
    Channel.find_each do |channel|
      unless channel.inactive_candidate?
        affected_channels_tomorrow.push channel if channel.inactive_candidate_tomorrow?
        next
      end

      begin
        channel.archive
        affected_channels.push(channel)
      rescue => e
        SlackClient.post_msg_to_manager(build_error_message(channel, e))
        raise e
      end
    end
    SlackClient.post_msg_to_manager(build_message(affected_channels, affected_channels_tomorrow))
    if affected_channels.size > 0
      SlackClient.post_msg_via_api(channel: ENV["NOTICE_CHANNEL"], text: build_message_for_public(affected_channels))
    end
  end

  private

  def build_error_message(channel, e)
    message = <<~EOS
      There was some problem on 'ArchivingJob' execution:
      Channel which raised error is #{channel.name}(#{channel.cid}).
      Error Message: #{e.message}
      Backtrace:
      #{e.backtrace.join("\n")}
    EOS
  end

  def build_message(channels, channels_tomorrow)
    message = \
      if !channels.empty?
        message = <<~EOS
          ArchivingJob performed result:
          Affected Channel(#{channels.size}) => #{channels.map(&:name).join(', ')}
        EOS
      else
        "ArchivingJob performed result: no affected channel"
      end
    unless channels_tomorrow.empty?
      message += "\nProtip: #{channels_tomorrow.map(&:name).join(', ')} may be archived."
    end
    message
  end

  def build_message_for_public(channels)
    names = channels.map { |channel| "##{channel.name}" }.join(', ')
    "Channel RIP: #{names}"
  end
end
