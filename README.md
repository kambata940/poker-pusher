# Pusher

## Setup

Install all dependencies

```
bundle
```

Use the project's git hooks

```bash
git config core.hooksPath hooks
```

## Booting the server

Starting the fake router server
```bash
be thin start -R router.ru -p 9290
```

Starting the WebSocket worker server
```bash
be thin start -R config.ru -p 9292
```

## Play with it
Open the html client `test-client.html` a browser and send start sending messages :)
