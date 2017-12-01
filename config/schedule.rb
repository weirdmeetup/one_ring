# frozen_string_literal: true

# Learn more: http://github.com/javan/whenever
require File.expand_path(File.dirname(__FILE__) + "/environment")

env :PATH, ENV["PATH"]
set :output, "log/cron.log"

every 1.day, at: "09:20 pm" do
  runner "SyncChannelsJob.perform_now"
end

every 1.day, at: "09:40 pm" do
  runner "ArchivingJob.perform_now"
end

every 5.minutes do
  runner "SyncMessagesJob.perform_now"
end
