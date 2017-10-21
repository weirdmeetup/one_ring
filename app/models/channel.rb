require 'slack_client'

class Channel < ApplicationRecord
  WARNING_LIMIT = 7.days.ago
  ACHIVING_LIMIT = 23.days.ago

  has_many :messages

  scope :alive, -> { where(active: true) }
  scope :achiving_candidate, -> { alive.where('warned_at < ?', Channel::ACHIVING_LIMIT) }

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

  def last_message
    messages.order(id: :desc).first
  end

  def default_channel?
    name.start_with?('_')
  end

  def inactive_candidate?
    return false if default_channel?
    last_message = channel.last_message
    !last_message || last_message.created_at < Channel::WARNING_LIMIT
  end

  def inactive?
    last_message = channel.last_message
    !last_message || last_message.created_at < Channel::ACHIVING_LIMIT
  end

  def archive
    client = SlackClient.build_api_client
    client.channels_archive(channel: cid)
    update(active: false)
  end
end
