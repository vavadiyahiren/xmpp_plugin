import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_xmpp/xmpp_plugin.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static late XmppConnection flutterXmpp;

  Future<void> connect() async {
    final auth = {
      "user_jid": "jid/resource",
      "password": "password",
      "host": "xmpphost",
      "port": "5222"
    };

    flutterXmpp = XmppConnection(auth);
    await flutterXmpp.start(_onReceiveMessage, _onError);
    await flutterXmpp.login();
  }

  Future<void> _onReceiveMessage(dynamic event) async {
    // TODO : Handle the receive event
  }

  void _onError(Object error) {
    // TODO : Handle the Error event
  }

  Future<void> disconnectXMPP() async => await flutterXmpp.logout();

  Future<void> joinMucGroups(List<String> allGroupsId) async {
    await flutterXmpp.joinMucGroups(allGroupsId);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('XMPP Plugin'),
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                await connect();
              },
              child: Text('Connect'),
            ),
            SizedBox(
              height: 10,
            ),
            ElevatedButton(
              onPressed: () async {
                await flutterXmpp.sendMessageWithType(
                    "xyz@domain", "Hi", "MSGID");
              },
              child: Text('Send Message'),
            ),
            SizedBox(
              height: 10,
            ),
            ElevatedButton(
              onPressed: () async {
                await joinMucGroups(['your groupID']);
              },
              child: Text('Join Group'),
            ),
            SizedBox(
              height: 10,
            ),
            ElevatedButton(
              onPressed: () async {
                await flutterXmpp.sendMessageWithType(
                    "xyz@domain", "Hi", "MSGID");
              },
              child: Text('Send Group Message'),
            ),
            SizedBox(
              height: 10,
            ),
            ElevatedButton(
              onPressed: () async {
                await disconnectXMPP();
              },
              child: Text('Log Out'),
            ),
          ],
        ),
      ),
    );
  }
}
