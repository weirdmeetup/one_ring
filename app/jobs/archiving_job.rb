class ArchivingJob < ApplicationJob
  queue_as :default

  def perform(*args)
    affected_channels = Channel.achiving_candidate.each_with_object([]) do |channel, chs|
      if channel.inactive?
        bot_client.chat_postMessage(
          channel: channel.cid,
          text: ":red_circle: 이 채널은 30일 이상 대화가 없습니다. 여러분 안녕"
        )
        channel.archive
        chs.push(channel)
      end
    end
    manage_client.chat_postMessage(channel: '#' + ENV['MANAGE_CHANNEL'], text: build_message(affected_channels), as_user:true)
  rescue => e
    message = <<~EOS
    There was some problem on 'WarningJob' execution:
    Channel which raised error is #{channel.name}(#{channel.cid}).
    Error Message: #{e.message}
    Backtrace:
    #{e.backtrace.join("\n")}
    EOS
    manage_client.chat_postMessage(channel: '#' + ENV['MANAGE_CHANNEL'], text: message, as_user:true)
  end

  private

  def bot_client
    @bot_client ||= SlackClient.build_bot_client
  end

  def manage_client
    @manage_client ||= SlackClient.build_manage_client
  end

  def build_message(channels)
    if channels.size > 0
      message = <<~EOS
      WarningJob performed result:
      Affected Channel(#{channels.size}) => #{channels.map(&:name).join(', ')}
      EOS
    else
      "ArchivingJob performed result: no affected channel"
    end
  end
end
