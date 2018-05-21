require 'sinatra'
require 'faye/websocket'
require 'pry'
require 'securerandom'
require 'json'
require 'uri'

Faye::WebSocket.load_adapter('thin')

WebClients = {}
WebClient = Struct.new(:id, :socket)

get '/' do
  if Faye::WebSocket.websocket?(request.env)
    id = SecureRandom.uuid
    WebClients[id] = WebClient.new(id, Faye::WebSocket.new(request.env))

    WebClients[id].socket.on :open do |event|
      puts 'Open'

      new_client = WebClients[id]

      EM.next_tick do
        new_client.socket.send({id: new_client.id}.to_json)

        WebClients.each do |(id, c)|
          next if id == new_client.id

          c.socket.send "New client #{c.id}"
        end
      end
    end

    WebClients[id].socket.on :message do |event|
      puts event.data
      WebClients[id].socket.send(event.data)
    end

    WebClients[id].socket.on :close do |event|
      p [:close, event.code, event.reason]
      WebClients.delete(id)
    end

    WebClients[id].socket.rack_response
  else
    'Pusher 1.0.1'
  end
end
