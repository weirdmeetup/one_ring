class AchivingJob < ApplicationJob
  queue_as :default

  def perform(*args)
    Channel.achiving_candidate.each do |channel|
      if channel.inactive?
        bot_client.chat_postMessage(
          channel: channel.cid,
          text: ":red_circle: 이 채널은 30일 이상 대화가 없습니다. 여러분 안녕"
        )
        channel.archive
      end
    end
  end

  private

  def bot_client
    @bot_client ||= SlackClient.build_bot_client
  end
end
