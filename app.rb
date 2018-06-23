require 'sinatra'
require 'faye/websocket'
require 'pry'
require 'securerandom'
require 'json'
require 'uri'
require 'jwt'
require 'http'

Faye::WebSocket.load_adapter('thin')

SOCKET_STORE = {}

module Comunication
  extend self

  ROUTER_URL = 'http://localhost:9290'.freeze

  def connect(socket, user_id:, token:)
    response = HTTP.post("#{ROUTER_URL}/users", form: { token: token, server_id: 1 })

    unless response.code == 200
      p [:unauthorized]
      socket.send(status: :forbidden)
      socket.close
      return
    end

    p [:connect]

    SOCKET_STORE[user_id] = socket
  end

  def disconnect(socket)
    p [:disconnect]

    user_id, _socket = SOCKET_STORE.find { |s| s == socket }

    EM.next_tick do
      HTTP.delete("#{ROUTER_URL}/users", form: { user_id: user_id, server_id: 1 })
    end

    SOCKET_STORE.delete(user_id)
  end
end

# TODO: move to the client server
post '/client_server/login' do
  headers 'Access-Control-Allow-Origin' => '*'
  # validate the user
  token = JWT.encode({ user_id: params['user_id'] }, nil, 'none')

  [200, { token: token }.to_json]
end

get '/web_socket' do
  if Faye::WebSocket.websocket?(request.env)
    socket = Faye::WebSocket.new(request.env)

    socket.on :message do |message|
      data = JSON.parse message.data

      case data['type'].to_sym
      when :register
        EM.next_tick do
          Comunication.connect(socket, user_id: data['user_id'], token: data['token'])
        end
      end
    end

    socket.on(:close) do
      Comunication.disconnect(socket)
      socket = nil
    end

    socket.rack_response
  else
    'Pusher 1.0.1'
  end
end

get '/users' do
  headers 'Access-Control-Allow-Origin' => '*'

  [200, SOCKET_STORE.keys.to_json]
end

post '/messages' do
  headers 'Access-Control-Allow-Origin' => '*'
  body = JSON.parse params['body']

  # FORMAT: status: [:ok, :forbidden], type: ['text', 'json'], content: [JSON, TEXT]
  # The status code is set by the Web socket server
  if SOCKET_STORE[params['user_id']].send(body.merge(status: :ok).to_json)
    200
  else
    400
  end
end
