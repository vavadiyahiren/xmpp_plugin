# xmpp_plugin

1. Connect to the xmpp server

```
final param = {
      "user_jid":"jid/resource",
      "password": "password",
      "host": "xmpphost",
      "port": "5222",
      "nativeLogFilePath": "filepath",
      "requireSSLConnection": true,
      "autoDeliveryReceipt": true,
      "useStreamManagement": false,
      "automaticReconnection": true,
};

XmppConnection xmppConnection = XmppConnection(param);

await xmppConnection.start(_onError);
await xmppConnection.login();

```

2. Send message to one-one chat

```
await xmppConnection.sendMessageWithType("xyz@domain", "Hi", "MSGID");
await xmppConnection.sendGroupMessageWithType("xyz@conference.domain", "Hi", "MSGID");
```

3. Disconnect the xmppConnection

```
xmppConnection.logout();
```

4. Creating a MUC

```
xmppConnection.createMUC("groupName", true);
```

5. Joining  MUC

```
xmppConnection.joinMucGroups(List<String> allGroupsId)

```

6. Sending Custom Message

```
await xmppConnection.sendCustomMessage("xyz@domain", "Hi", "MSGID","customTest");
await xmppConnection.sendCustomGroupMessage("xyz@conference.domain", "Hi", "MSGID","customText");

```

7. Sending Delivery Receipt

```
await flutterXmpp.sendDelieveryReceipt("xyz@domain", "Received-Message-Id", "Receipt-Id");
```

8. Adding members to MUC

```
await flutterXmpp.addMembersInGroup("groupName", List<String> allMembersId);
```

9. Adding admins to MUC

```
await flutterXmpp.addAdminsInGroup("groupName", List<String> allMembersId);
```

10. Get member list from the MUC

```
await flutterXmpp.getMembers("groupName");
```

11. Get Admin list from the MUC 

```
await flutterXmpp.getAdmins("groupName");
```

12. Get Owner list from the MUC

```
await flutterXmpp.getOwners("groupName");
```

13. Remove members from the MUC

```
await flutterXmpp.removeMember("groupName", List<String> allMembersId);
```

14. Remove admins from group

```
await flutterXmpp.removeAdmin("groupName", List<String> allMembersId);
```

15. Get online member count from group

```
var onlineCount = await flutterXmpp.getOnlineMemberCount("groupName");
```

16. Get last activity of the jid

```
var lastseen = await flutterXmpp.getLastSeen(jid);
```

17. Get the list of my rosters

```
await flutterXmpp.getMyRosters();
```

18. Creating a roster entry

```
await flutterXmpp.createRoster(jid);
```

19. Join single MUC

```
await flutterXmpp.joinMucGroup(groupId);
```

20. Request MAM Messages

```
await flutterXmpp.requestMamMessages(userJid, requestSince, requestBefore, limit);
```

21. Update Typing Status

```
await flutterXmpp.changeTypingStatus(userJid, typingStatus);
```

22. Update Presence Type

```
await flutterXmpp.changePresenceType(presenceType, presenceMode);
```

23. Get Connection status

```
XmppConnectionState connectionStatus = await flutterXmpp.getConnectionStatus();
```

24. Get ErrorResponse Event

```
void onXmppError(ErrorResponseEvent errorResponseEvent) {
    // TODO : Handle the Error Event
}
```

25. Get SuccessResponse Event

```
void onSuccessEvent(SuccessResponseEvent successResponseEvent) {
    // TODO : Handle the Success Event
}
```

26. Get ChatMessage Event

```
void onChatMessage(MessageChat messageChat) {
    // TODO : Handle the ChatMessage Event
}
```

27. Get GroupMessage status

```
void onGroupMessage(MessageChat messageChat) {
    // TODO : Handle the GroupMessage Event
}
```

28. Get NormalMessage status

```
void onNormalMessage(MessageChat messageChat) {
    // TODO : Handle the NormalMessage Event
}
```

29. Get PresenceChange status

```
void onPresenceChange(PresentModel presentModel) {
    // TODO : Handle the PresenceChange Event
}
```

30. Get ChatStateChange status

```
void onChatStateChange(ChatState chatState) {
    // TODO : Handle the ChatState Event
}
```

31. Get ConnectionEvent status

```
void onConnectionEvents(ConnectionEvent connectionEvent) {
    // TODO : Handle the ConnectionEvent Event
}
```


Contact
-------
 
You can reach us via mail(hiren@xrstudio.in) the if you have questions or need support.
