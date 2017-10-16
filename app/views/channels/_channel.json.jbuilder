json.extract! channel, :id, :cid, :name, :master, :last_updated_at, :created_at, :updated_at
json.url channel_url(channel, format: :json)
