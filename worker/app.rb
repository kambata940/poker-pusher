# frozen_string_literal: true

require 'sinatra'
require 'faye/websocket'
require 'pry'
require 'securerandom'
require 'json'
require 'uri'
require 'jwt'
require 'http'

require 'sinatra/reloader' if development?

Faye::WebSocket.load_adapter('thin')

SOCKET_STORE = {}

module Comunication
  extend self

  ROUTER_URL = 'http://localhost:9290'

  def connect(socket, user_id:, token:, base_url:)
    response = HTTP.post("#{ROUTER_URL}/users", form: { token: token, worker_url: base_url })

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

    user_id, _socket = SOCKET_STORE.find { |(_, s)| s == socket }

    raise 'Not disconnect user missing' unless user_id

    EM.next_tick do
      HTTP.delete("#{ROUTER_URL}/users", form: { user_id: user_id, server_id: 1 })
    end

    SOCKET_STORE.delete(user_id)
  end
end

helpers do
  def base_url
    @base_url ||= "#{request.env['rack.url_scheme']}://127.0.0.1:#{ENV['WORKER_PORT']}"
  end
end

get '/web_socket' do
  if Faye::WebSocket.websocket?(request.env)
    socket = Faye::WebSocket.new(request.env, nil, ping: 5)

    socket.on :message do |message|
      data = JSON.parse message.data

      case data['type'].to_sym
      when :register
        EM.next_tick do
          Comunication.connect(socket,
                               user_id: data['user_id'],
                               token: data['token'],
                               base_url: base_url)
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

post '/messages' do
  body = JSON.parse params['body']

  # FORMAT: status: [:ok, :forbidden], type: ['text', 'json'], content: [JSON, TEXT]
  # The status code is set by the Web socket server
  if SOCKET_STORE[params['user_id']].send(body.merge(status: :ok).to_json)
    200
  else
    400
  end
end
