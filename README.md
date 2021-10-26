# xmpp_plugin

1. Connect to the xmpp server

```
final param = {
      "user_jid":"jid/resource",
      "password": "password",
      "host": "xmpphost",
      "port": "5222"
};

XmppConnection xmppConnection = XmppConnection(param);

await xmppConnection.start(_onReceiveMessage, _onError);
await xmppConnection.login();

```

2. Send message to one-one chat

```
await xmppConnection.sendMessageWithType("xyz@domain", "Hi", "MSGID");
```

3. Receive message from server

```
Future _onReceiveMessage(dynamic event) async {
       // TODO : Handle the receive event
}
```

4. Disconnect the xmppConnection

```
xmppConnection.logout();
```

5. Joining/Creaging the MUC

```
xmppConnection.joinMucGroups(List<String> allGroupsId)

```

6. Sending group message 

```
await xmppConnection.sendGroupMessageWithType("xyz@conference.domain", "Hi", "MSGID");
```

# To be Added

 - MAM
 - Presence
 - Last Activity
