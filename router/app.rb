# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader' if development?
require 'pry'
require 'securerandom'
require 'json'
require 'uri'
require 'jwt'
require 'http'

WORKER_URL_BY_USER = {}

post '/messages' do
  EM.next_tick do
    worker_url = WORKER_URL_BY_USER[params['user_id']]

    if worker_url
      HTTP.post("#{worker_url}/messages",
                form: { user_id: params['user_id'], body: params['body'] })
    end
  end

  200
end

# TODO: move to the client server
post '/client_server/login' do
  # validate the user
  token = JWT.encode({ user_id: params['user_id'] }, nil, 'none')

  [200, { token: token }.to_json]
end

get '/users' do
  [200, WORKER_URL_BY_USER.keys.to_json]
end

post '/users' do
  # TODO: Use more secure JWT algorithm
  payload, = JWT.decode params['token'], nil, false

  WORKER_URL_BY_USER[payload['user_id']] = params['worker_url']

  200
rescue JWT::DecodeError
  403
end

delete '/users' do
  WORKER_URL_BY_USER.delete(params['user_id'])

  200
end
