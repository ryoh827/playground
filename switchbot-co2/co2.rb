# frozen_string_literal: true

require 'httpclient'
require 'securerandom'
require 'base64'
require 'json'

def get_metor_status
  token = ENV['SWITCHBOT_TOKEN']
  secret = ENV['SWITCHBOT_SECRET']
  device_id = ENV['SWITCHBOT_DEVICE_ID']

  # to milliseconds

  t = (Time.now.to_f * 1000).to_i
  nonce = SecureRandom.uuid
  payload = "#{token}#{t}#{nonce}"
  sign = Base64.strict_encode64(OpenSSL::HMAC.digest('sha256', secret, payload))

  header = {
    'Authorization' => token,
    'sign' => sign,
    'nonce' => nonce,
    't' => t.to_s
  }

  client = HTTPClient.new
  url = "https://api.switch-bot.com/v1.1/devices/#{device_id}/status"
  response = client.get(url, header:)

  body = JSON.parse(response.body)['body']
end

status = get_metor_status
pp status
