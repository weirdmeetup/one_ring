# frozen_string_literal: true

class Message < ApplicationRecord
  belongs_to :channel

  scope :recent, -> { order(created_at: :desc) }
end
