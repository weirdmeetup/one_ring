# frozen_string_literal: true

class ChannelsController < ApplicationController
  before_action :set_channel, only: %i[show edit update destroy]

  # GET /channels
  def index
    @channels = Channel.all
  end

  # GET /channels/1
  def show
    @messages = @channel.messages.last(10)
  end

  # GET /channels/new
  def new
    @channel = Channel.new
  end

  # POST /channels
  def create
    @channel = Channel.new(channel_params)

    if @channel.save_with_slack
      redirect_to @channel, notice: "Channel was successfully created."
    else
      render :new
    end
  end

  # DELETE /channels/1
  def destroy
    @channel.archive
    redirect_to channels_url, notice: "Channel was successfully archived."
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_channel
    @channel = Channel.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def channel_params
    params.require(:channel).permit(:name, :master)
  end
end
