class WarningJob < ApplicationJob
  queue_as :default

  def perform
    Channel.all.each do |channel|
      if channel.inactive_candidate?
        next if channel.warned_at # Ignore

        bot_client.chat_postMessage(
          channel: channel.cid,
          text: ":large_blue_circle: 이 채널은 7일 이상 대화가 없습니다. 한 달 이상 대화가 없을 경우 자동으로 아카이빙됩니다."
        )
        channel.update(warned_at: Time.zone.now)
      else
        channel.update(warned_at: nil)
      end
    end
  end

  private

  def bot_client
    @bot_client ||= SlackClient.build_bot_client
  end
end
