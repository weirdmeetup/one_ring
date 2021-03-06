# frozen_string_literal: true

class SyncChannelsJob < ApplicationJob
  queue_as :default

  def perform(*_args)
    channels.each do |ch|
      next if ch.is_archived

      unless ch.is_member
        invite_to_channel(ch.id, ch.name)
      end

      obj = Channel.find_or_initialize_by(cid: ch.id) do |obj|
        obj.cid = ch.id
      end
      obj.name = ch.name
      obj.master ||= "Nobody"
      obj.active = !ch.is_archived
      obj.save
    end
    SlackClient.post_msg_to_manager("Sync channels is finished.")
  end

  private

  def channels
    @channels ||= SlackClient.channels_list.channels
  end

  def invite_to_channel(cid, cname)
    Rails.logger.info "Bot can't trace #{cname}. Try to invite him"
    ch_of_user = SlackClient.channels_info(channel: cid).channel
    was_joined = ch_of_user.is_member
    SlackClient.channels_join(name: cname) unless was_joined
    SlackClient.channels_invite(channel: cid, user: bot_uid)
    SlackClient.channels_leave(channel: cid) unless ch_of_user.is_general || was_joined
  end

  def bot_uid
    @bot_uid ||= SlackClient.bot_uid
  end
end
