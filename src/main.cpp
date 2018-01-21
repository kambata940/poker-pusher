#include "common.h"

#include "client_server.h"

int main(int argc, char **argv) 
{
    ClientServer server;
    server.onAuthentication([](ClientID id) { return id != 12345;});
    server.run(4567);

	return 0;
}
         
