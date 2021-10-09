# xmpp_plugin

1. Connect to the xmpp server

final param = {
      "user_jid":"jid/resource",
      "password": "password",
      "host": "xmpphost",
      "port": "5222"
};

XmppConnection xmppConnection = XmppConnection(param);

await xmppConnection.start(_onReceiveMessage, _onError);
await xmppConnection.login();

2. Send message to one-one chat

await xmppConnection.sendMessageWithType(toJid, body, msgId);

3. Receive message from server

Future _onReceiveMessage(dynamic event) async {
       // TODO : Handle the receive event
}

4. Disconnect the xmppConnection

xmppConnection.logout();

# To be Added

 - Group chat
 - MAM
 - Presence
 - Last Activity
