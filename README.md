# Pusher

## Setup

Install all dependencies

```
bin/install
```

## Booting the server

Starting the router server
```bash
thin start -R router/config.ru -p 9290
```

Starting the WebSocket worker server
```bash
thin start -R worker/config.ru -p 9292
```

## Play with it
Open the html client `stubs/test-client.html` a browser and send start sending messages :)
