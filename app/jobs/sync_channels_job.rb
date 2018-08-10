# frozen_string_literal: true

class SyncChannelsJob < ApplicationJob
  queue_as :default

  def perform(*_args)
    channels.each do |c|
      ch = c.is_archived ? c : channel(c.id)

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

  def channel(cid)
    ch = SlackClient.channels_info(channel: cid).channel
    return ch if ch.is_member
    invite_to_channel(cid, ch.name)

    SlackClient.channels_info(channel: cid).channel
  end

  def invite_to_channel(cid, cname)
    Rails.logger.info "Bot can't trace #{cname}. Try to invite him"
    ch_of_user = SlackClient.channels_info(channel: cid).channel
    was_joined = ch_of_user.is_member
    SlackClient.channels_join(name: cname) unless was_joined
    SlackClient.channels_invite(channel: cid, user: bot_uid)
  rescue Slack::Web::Api::Errors::SlackError => e
    if e.message == 'already_in_channel'
      # Do nothing
    else
      raise e
    end
  ensure
    unless ch_of_user.is_general || was_joined
      SlackClient.channels_leave(channel: cid)
    end
  end

  def bot_uid
    @bot_uid ||= SlackClient.bot_uid
  end
end
