# frozen_string_literal: true

class Message < ApplicationRecord
  belongs_to :channel

  scope :recent, -> { order(created_at: :desc) }

  delegate :name, to: :channel, prefix: true

  def self.unique_user(from)
    select("user").distinct.where(created_at: from..Time.zone.now).count
  end

  def self.count_from(from)
    where(created_at: from..Time.zone.now).count
  end

  def self.count_for_channel_from(from)
    Message.
      select('channel_id, count(*) as count').
      includes(:channel).
      where(created_at: from..Time.zone.now).
      group(:channel_id).
      order('count desc').
      limit(20)
  end
end
