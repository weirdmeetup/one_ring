class SyncChannelsJob < ApplicationJob
  queue_as :default

  def perform(*args)
    channels.each do |c|
      if c.is_archived
        Rails.logger.info "#{c.name} is skiped because it archived"
        next
      end

      ch = channel(c.id)
      unless ch
        Rails.logger.info "Bot can't trace #{c.name}. Please invite him"
        next
      end

      obj = Channel.find_or_create_by(cid: ch.id) do |obj|
        obj.name = ch.name
        obj.master = "Nobody"
      end
      obj.save
    end
  end

  private

  def client
    @client ||= Slack::Web::Client.new
  end

  def channels
    @channels ||= client.channels_list.channels
  end

  def channel(cid)
    ch = client.channels_info(channel: cid).channel
    if ch.is_member
      ch
    else
      false
    end
  end
end
