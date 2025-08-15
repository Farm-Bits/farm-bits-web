# Throttle requests to 5 requests per second per IP address
Rack::Attack.throttle('req/ip', limit: 5, period: 1.second) do |req|
  req.ip
end
