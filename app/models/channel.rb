require 'slack_client'

class Channel < ApplicationRecord
  has_many :messages

  def self.init_with(params)
    channel = new(params).tap do |obj|
      api_client = SlackClient.build_api_client
      resp = api_client.channels_create(name: params[:name]).channel
      obj.cid = resp.id
      bot_client = SlackClient.build_bot_client
      api_client.channels_invite(channel: obj.cid, user: bot_client.auth_test.user_id)
      bot_client.chat_postMessage(channel: obj.cid, text: "<#{obj.master}>님, 요청하신 채널이 생성되었습니다.")
    end
  end

  def archive
    client = SlackClient.build_api_client
    client.channels_archive(channel: cid)
    update(active: false)
  end
end
