# Learn more: http://github.com/javan/whenever
require File.expand_path(File.dirname(__FILE__) + "/environment")

env :PATH, ENV['PATH']
set :output, 'log/cron.log'

every 1.day, at: '09:30 pm' do
  runner "WarningJob.perform_now"
end

every 1.day, at: '09:40 pm' do
  runner "ArchivingJob.perform_now"
end
