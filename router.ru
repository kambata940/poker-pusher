require 'sinatra'
require 'pry'
require 'securerandom'
require 'json'
require 'uri'
require 'jwt'

post '/users' do
  puts params['server_id'] # REQUIRED
  # TODO: Use more secure JWT algorithm
  payload, = JWT.decode params['token'], nil, false
  user_id = payload['user_id']

  user_id ? [200, { user_id: user_id }.to_json] : 403
end

delete '/users' do
  puts params['server_id'] # REQUIRED
  puts params['user_id'] # REQUIRED
  200
end

run Sinatra::Application
