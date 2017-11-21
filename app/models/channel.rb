# frozen_string_literal: true

class Channel < ApplicationRecord
  WARNING_LIMIT = 7.days.ago
  ACHIVING_LIMIT = 23.days.ago

  has_many :messages

  scope :alive, -> { where(active: true) }
  scope :achiving_candidate, -> { alive.where("warned_at < ?", Channel::ACHIVING_LIMIT) }

  validates :name, presence: true, uniqueness: true
  validates :master, presence: true

  def save_with_slack
    return false if invalid?
    user = SlackClient.users_info(user: master)
    unless user
      errors[:master] << "uid is not valid"
      return false
    end

    cid = SlackClient.channels_create(name: name).channel.id
    SlackClient.channels_invite(channel: cid, user: SlackClient.bot_uid)
    SlackClient.channels_leave(channel: cid)
    SlackClient.post_msg_as_bot(
      channel: cid,
      text: "<@#{master}>님, 요청하신 채널이 생성되었습니다."
    )
    SlackClient.post_msg_via_api(channel: ENV["NOTICE_CHANNEL"], text: "`신규채널` <##{cid}>")
    SlackClient.post_msg_via_api(channel: ENV["CHANNEL_CHANNEL"], text: "`신규채널` <##{cid}>")
    self.cid = cid
    save!
  end

  def last_message
    messages.order(created_at: :desc).first
  end

  def days_from_last_message
    last_time = messages.order(created_at: :desc).first&.created_at || created_at
    ((Time.zone.now - last_time) / 86_400).to_i
  end

  def default_channel?
    name.start_with?("_")
  end

  def inactive_candidate?
    return false unless active
    return false if default_channel?
    return false if created_at > 7.days.ago
    !last_message || last_message.created_at < Channel::WARNING_LIMIT
  end

  def inactive?
    return false unless active
    return false if warned_at.nil?
    !last_message || last_message.created_at < Channel::ACHIVING_LIMIT
  end

  def unarchive
    return false if invalid?

    user = SlackClient.users_info(user: master)
    return false unless user
    SlackClient.channels_unarchive(channel: cid)
    SlackClient.channels_invite(channel: cid, user: SlackClient.bot_uid)
    SlackClient.channels_leave(channel: cid)
    SlackClient.post_msg_as_bot(channel: cid, text: "<@#{master}>님, 요청하신 채널이 살아났습니다.")
    SlackClient.post_msg_via_api(channel: ENV["NOTICE_CHANNEL"], text: "`부활채널` #<#{cid}>")

    update!(active: true, archived_at: nil)
  end

  def archive
    SlackClient.channels_archive(channel: cid)
    update(active: false, archived_at: Time.zone.now)
  end
end
