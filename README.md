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

8. Sending Delivery Receipt

```
await flutterXmpp.sendDelieveryReceipt("xyz@domain", "Received-Message-Id", "Receipt-Id");
```

9. Adding members to MUC

```
await flutterXmpp.addMembersInGroup("groupName", List<String> allMembersId);
```

10. Adding admins to MUC

```
await flutterXmpp.addAdminsInGroup("groupName", List<String> allMembersId);
```

11. Get member list from the MUC

```
await flutterXmpp.getMembers("groupName");
```

12. Get Admin list from the MUC 

```
await flutterXmpp.getAdmins("groupName");
```

13. Get Owner list from the MUC

```
await flutterXmpp.getOwners("groupName");
```

14. Remove members from the MUC

```
await flutterXmpp.removeMember("groupName", List<String> allMembersId);
```

15. Remove admins from group

```
await flutterXmpp.removeAdmin("groupName", List<String> allMembersId);
```

16. Get online member count from group

```
var onlineCount = await flutterXmpp.getOnlineMemberCount("groupName");
```

17. Get last activity of the jid

```
var lastseen = await flutterXmpp.getLastSeen(jid);
```

18. Get the list of my rosters

```
 await flutterXmpp.getMyRosters();
```

19. Creating a roster entry

```
await flutterXmpp.createRoster(jid);
```

20. Join single MUC

```
await flutterXmpp.joinMucGroup(groupId);
```

# To be Added

 - MAM
