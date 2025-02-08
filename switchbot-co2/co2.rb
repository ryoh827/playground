# frozen_string_literal: true

require 'net/http'
require 'base64'
require 'json'

token = ENV['SWITCHBOT_TOKEN']
secret = ENV['SWITCHBOT_SECRET']
device_id = ENV['SWITCHBOT_DEVICE_ID']

# to milliseconds
t = (Time.now.to_f * 1000).to_i
nonce = SecureRandom.uuid

sign = OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha256'), secret, "#{token}#{t}#{nonce}")
base64_sign = Base64.strict_encode64(sign)

client = Net::HTTP.new('api.switch-bot.com', 443)
client.use_ssl = true

headers = {
  'Content-Type' => 'application/json',
  'charset' => 'utf-8',
  'Authorization' => token,
  'sign' => base64_sign,
  'nonce' => nonce,
  't' => t.to_s
}

res = client.get("/v1.1/devices/#{device_id}/status", headers)
# res = client.get('/v1.1/devices', headers)

pp JSON.parse(res.body)
