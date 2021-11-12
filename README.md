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
await xmppConnection.sendGroupMessageWithType("xyz@conference.domain", "Hi", "MSGID");
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

5. Creating a MUC

```
xmppConnection.createMUC("groupName", true);
```

6. Joining  MUC

```
xmppConnection.joinMucGroups(List<String> allGroupsId)

```

7. Sending Custom Message

```
await xmppConnection.sendCustomMessage("xyz@domain", "Hi", "MSGID","customTest");
await xmppConnection.sendCustomGroupMessage("xyz@conference.domain", "Hi", "MSGID","customText");

```

9. Sending Delivery Receipt

```
await flutterXmpp.sendDelieveryReceipt("xyz@domain", "Received-Message-Id", "Receipt-Id");
```

# To be Added

 - MAM
 - Presence
 - Last Activity
