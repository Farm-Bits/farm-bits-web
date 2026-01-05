Sidekiq.configure_server do |config|
  if Rails.env.development?
    config.logger.level = Logger::DEBUG
  end

  config.redis = { url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/0') }
end

Sidekiq.configure_client do |config|
  if Rails.env.development?
    config.logger.level = Logger::DEBUG
  end

  config.redis = { url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/0') }
end
