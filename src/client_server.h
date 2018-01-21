#pragma once

#include <uWS/uWS.h>

using namespace uWS;

class ClientServer
{
public:
    ClientServer();
    ClientServer(const ClientServer&) = delete;
    ClientServer& operator=(const ClientServer&) = delete;
    ~ClientServer();
    
    bool run(Port port);
    void send(std::initializer_list<ClientID> idList, const std::string& message);
    
    typedef std::function<bool(ClientID)> AuthCallback;
    void onAuthentication(AuthCallback callback);
    
// Socket callbacks
private:
    void handleConnection(WebSocket<SERVER>* socket, HttpRequest req);
    void handleDisconnection(WebSocket<SERVER>* socket, int code, char *message, size_t length);
    
private:
    Hub mHub;
    AuthCallback mAuthCB;
};

struct ClientData
{
    ClientID mClient;
    TableID mTable;

    ClientData(ClientID client, TableID table = 0) : mClient(client), mTable(table) {}
};
