# frozen_string_literal: true

class DashboardController < ApplicationController
  def index
    uu_in_a_month = Message.unique_user(1.month.ago)
    uu_in_a_week = Message.unique_user(1.week.ago)
    msg_per_day = (Message.count_from(1.month.ago) / 30.5).round(2)
    channel_rank = Message.count_for_channel_from(1.month.ago)

    render :index, locals: {
      uu_in_a_month: uu_in_a_month,
      uu_in_a_week: uu_in_a_week,
      msg_per_day: msg_per_day,
      channel_rank: channel_rank,
    }
  end
end
