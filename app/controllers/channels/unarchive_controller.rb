# frozen_string_literal: true

class Channels::UnarchiveController < ApplicationController
  def new
    @channel = Channel.find(params[:channel_id])
    @channel.master = nil
    render :new
  end

  def create
    @channel = Channel.find(params[:channel_id])
    @channel.master = params[:channel][:master]
    if @channel.unarchive
      redirect_to @channel, notice: "Channel was successfully unarchive."
    else
      render :new
    end
  end
end
