require 'slack_client'

class Channel < ApplicationRecord
  has_many :messages

  def archive
    client = SlackClient.build_api_client
    client.channels_archive(channel: cid)
    update(active: false)
  end
end
