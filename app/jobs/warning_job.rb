class WarningJob < ApplicationJob
  queue_as :default

  def perform
    affected_channels = Channel.all.each_with_object([]) do |channel, chs|
      if channel.inactive_candidate?
        next if channel.warned_at # Ignore

        bot_client.chat_postMessage(
          channel: channel.cid,
          text: ":large_blue_circle: 이 채널은 7일 이상 대화가 없습니다. 한 달 이상 대화가 없을 경우 자동으로 아카이빙됩니다."
        )
        channel.update(warned_at: Time.zone.now)
        chs.push(channel)
      else
        # Bot message is not saved. meaning to say, L9 post Message has no affect to check.
        channel.update(warned_at: nil)
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
      "WarningJob performed result: no affected channel"
    end
  end
end
