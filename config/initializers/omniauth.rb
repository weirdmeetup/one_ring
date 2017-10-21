Rails.application.config.middleware.use OmniAuth::Builder do
  provider :slack_signin, ENV['MANAGE_API_KEY'], ENV['MANAGE_API_SECRET'], scope: 'identity.basic', team: ENV['MANAGE_TEAM']
end
