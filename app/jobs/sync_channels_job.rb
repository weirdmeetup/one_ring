require 'slack_client'

class SyncChannelsJob < ApplicationJob
  queue_as :default

  def perform(*args)
    channels.each do |c|
      if c.is_archived
        archived = Channel.find_by(cid: c.id)
        if archived&.active
          Rails.logger.info "#{c.name}'s status is not synced so let its status archived"
          archived.update(active: false)
        else
          next # ignore archived & un registered
        end
      end

      ch = channel(c.id)

      obj = Channel.find_or_initialize_by(cid: ch.id) do |obj|
        obj.cid = ch.id
        obj.name = ch.name
        obj.master = "Nobody"
      end
      obj.save
    end
  end

  private

  def api_client
    @api_client ||= SlackClient.build_api_client
  end

  def bot_client
    @bot_client ||= SlackClient.build_bot_client
  end

  def channels
    @channels ||= bot_client.channels_list.channels
  end

  def channel(cid)
    ch = bot_client.channels_info(channel: cid).channel
    return ch if ch.is_member
    invite_to_channel(cid, ch.name)

    bot_client.channels_info(channel: cid).channel
  end

  def invite_to_channel(cid, cname)
    Rails.logger.info "Bot can't trace #{cname}. Try to invite him"
    ch_of_user = api_client.channels_info(channel: cid).channel
    was_joined = ch_of_user.is_member
    api_client.channels_join(name: cname) unless was_joined
    api_client.channels_invite(channel: cid, user: bot_client.auth_test.user_id)
    api_client.channels_leave(channel: cid) unless was_joined
  end
end
