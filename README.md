# xmpp_plugin

1. Connect to the xmpp server

```
final param = {
      "user_jid":"username@domain/resource",
      "password": "password",
      "host": "xmpphost",
      "port": "5222"
};

FlutterXmpp xmppConnection = FlutterXmpp(param);

await flutterXmpp.start(_onReceiveMessage, _onError);
await flutterXmpp.login();

```

2. Send message to one-one chat

```
await flutterXmpp.sendMessageWithType("xyz@domain", "Hi", "MSGID");
```

3. Receive message from server

```
Future _onReceiveMessage(dynamic event) async {
       // TODO : Handle the receive event
}
```

4. Disconnect the xmppConnection

```
flutterXmpp.logout();
```

Next things to be added

 - Group chat
 - MAM
 - Presence
 - Last Activity
