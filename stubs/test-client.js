$(() => {
  const UI = {
    messageContainer: $('.messages'),
    messageBox: $('.message-box'),
    messageInput: $('.message-box input'),
    greatingHeader: $('.greating'),
    receiversSelect: $('.receivers'),
  };

  const USER_ID = `User-${(new Date()).getTime() % 10000}`
  console.log('The user ID is:', USER_ID);

  UI.greatingHeader.text(`Hello ${USER_ID}`);

  let RECEIVERS = [];
  setInterval(() => {
    $.get({
      url: '/router/users',
      success: (data) => {
        const receivers = JSON.parse(data);

        if (receivers.length === RECEIVERS.length && RECEIVERS.every(r => receivers.includes(r))) {
          return;
        }

        RECEIVERS = receivers;
        const selected = UI.receiversSelect.find(':selected').val()

        UI.receiversSelect.html(
          receivers.map((receiver) => $(`<option value="${receiver}" ${receiver === selected && 'selected'}>${receiver}</option>`))
        );
      }
    });
  },
  2000);

  UI.messageBox.submit((event) => {
    event.preventDefault();

    receiver = UI.receiversSelect.find(':selected').val();

    $.post({
      url: '/router/messages',
      data: {
        user_id: receiver,
        body: JSON.stringify({type: 'text', content: UI.messageInput.val()}),
      },
      success: () => UI.messageInput.val('')
    });
  });

  $.post({
    url: '/router/client_server/login',
    data: {
      user_id: USER_ID,
    },
    success: (data) => {
      const token = JSON.parse(data).token;
      connectSocket({UI, USER_ID, token});
    }
  })
})

function connectSocket({UI, USER_ID, token}) {
  const socket = new WebSocket(`ws://${window.location.host}/worker/web_socket`);

  setInterval(1000, () => { socket.send({type: 'ping'}); });

  socket.onopen = (event) => {
    console.log('Web socket connected');

    message = JSON.stringify({ type: 'register', user_id: USER_ID, token: token });
    socket.send(message);
  }

  socket.onclose = (event) => {
    console.log('Web socket closed');
  }

  socket.onmessage = (event) => {
    console.log(event.data);

    const {status, type, content} = JSON.parse(event.data);

    switch (status) {
      case 'reconnect':
        console.log('Reconnecting...');
        setTimeout(() => connectSocket({UI, token}), 300);

        break;
      case 'ok':
        if (type == 'text') {
          UI.messageContainer.append($(`<li>${content}</li>`));
        }
        break;
      default:
        throw 'Unexpected status code'
    }
  }
}
