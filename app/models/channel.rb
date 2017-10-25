class Channel < ApplicationRecord
  WARNING_LIMIT = 7.days.ago
  ACHIVING_LIMIT = 23.days.ago

  has_many :messages

  scope :alive, -> { where(active: true) }
  scope :achiving_candidate, -> { alive.where('warned_at < ?', Channel::ACHIVING_LIMIT) }

  validates :name, presence: true, uniqueness: true
  validates :master, presence: true

  def save_with_slack
    return false if invalid?

    api_client = SlackClient.build_api_client
    bot_client = SlackClient.build_bot_client
    cid = api_client.channels_create(name: name).channel.id
    api_client.channels_invite(channel: cid, user: bot_client.auth_test.user_id)
    bot_client.chat_postMessage(channel: cid, text: "<#{master}>님, 요청하신 채널이 생성되었습니다.")
    api_client.chat_postMessage(channel: ENV['NOTICE_CHANNEL'], text: "`신규채널` ##{cid}")
    self.cid = cid
    save!
  end

  def last_message
    messages.order(id: :desc).first
  end

  def default_channel?
    name.start_with?('_')
  end

  def inactive_candidate?
    return false if default_channel?
    return false if created_at > 7.days.ago
    !last_message || last_message.created_at < Channel::WARNING_LIMIT
  end

  def inactive?
    return false if warned_at.nil?
    !last_message || last_message.created_at < Channel::ACHIVING_LIMIT
  end

  def unarchive
    return false if invalid?
    api_client = SlackClient.build_api_client
    bot_client = SlackClient.build_bot_client
    api_client.channels_unarchive(channel: cid)
    api_client.channels_invite(channel: cid, user: bot_client.auth_test.user_id)
    bot_client.chat_postMessage(channel: cid, text: "<#{master}>님, 요청하신 채널이 살아났습니다.")
    api_client.chat_postMessage(channel: ENV['NOTICE_CHANNEL'], text: "`부활채널` ##{cid}")

    update!(active: true, archived_at: nil)
  end

  def archive
    client = SlackClient.build_api_client
    client.channels_archive(channel: cid)
    update(active: false, archived_at: Time.zone.now)
  end
end
