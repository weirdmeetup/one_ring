# frozen_string_literal: true

class ArchivingJob < ApplicationJob
  queue_as :default

  def perform(*_args)
    affected_channels = Channel.achiving_candidate.each_with_object([]) do |channel, chs|
      next unless channel.inactive?

      begin
        SlackClient.post_msg_as_bot(
          channel: channel.cid,
          text: ":red_circle: 이 채널은 30일 이상 대화가 없습니다. 여러분 안녕"
        )
        channel.archive
        chs.push(channel)
      rescue => e
        SlackClient.post_msg_to_manager(build_error_message(channel, e))
        raise e
      end
    end
    SlackClient.post_msg_to_manager(build_message(affected_channels))
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
end
