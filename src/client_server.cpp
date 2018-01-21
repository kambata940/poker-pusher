#include "common.h"

#include "client_server.h"

ClientServer::ClientServer()
    : mHub()
    , mAuthCB(nullptr)
{    
    mHub.onConnection([this](WebSocket<SERVER>* socket, HttpRequest req)
    {
        this->handleConnection(socket, req);
    });
    
    mHub.onDisconnection([this](WebSocket<SERVER>* socket, int code, char *message, size_t length)
    {
        this->handleDisconnection(socket, code, message, length);
    });
}

ClientServer::~ClientServer()
{
}

bool ClientServer::run(Port serverPort)
{
    if (mHub.listen(serverPort))
    {
        mHub.run();
        return true;
    }
    
    return false;
}

void ClientServer::send(std::initializer_list<ClientID> idList, const std::string& message)
{
    Group<SERVER>& clients = mHub.getDefaultGroup<SERVER>();
    
    clients.forEach([&message, &idList](WebSocket<SERVER>* socket)
    {
        ClientID currentID = *reinterpret_cast<ClientID*>(socket->getUserData());
       
        for (ClientID id : idList)
        {
            if (currentID == id)
            {
                socket->send(message.c_str());
            }
        }
    });
}

void ClientServer::onAuthentication(ClientServer::AuthCallback callback)
{
    mAuthCB = callback;
}

void ClientServer::handleConnection(WebSocket<SERVER>* socket, uWS::HttpRequest req)
{
    try
    {
        ///@note The client ID is kept in the url. Erase the first char, because it is slash.
        ///@todo Change this later?
        ClientID clientID = std::stoul(req.getUrl().toString().erase(0, 1));
        
        bool closeSocket = false;
        if (mAuthCB)
        {
            closeSocket = ! mAuthCB(clientID);
        }
        
        if (closeSocket)
        {
            socket->close();
        }
        else
        {
            socket->setUserData(new ClientData(clientID));
        
            std::cout << "Connected user with ID: " << clientID << std::endl;
        }
    }
    catch (std::exception& e)
    {
        ///@todo Add this in some logger system??
        std::cerr << "Exception caught: " << e.what() << std::endl;
        
        socket->close();
    } 
}

void ClientServer::handleDisconnection(WebSocket<SERVER>* socket, int code, char* message, size_t length)
{
    ClientData* data = reinterpret_cast<ClientData*>( socket->getUserData() );
    
    std::cout << "Disconnected user with ID: " << data->mClient << std::endl;
    
    delete data;
}
