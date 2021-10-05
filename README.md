# flutter_xmpp

[XMPP](https://xmpp.org/) for realtime chat communication,
this plugin just only work for android ..

## SORY THIS PROJECT IS NOT MAINTENANCE ..

## Getting Started

### Example

```
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:flutter_xmpp/flutter_xmpp.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String rerceiveMessageFrom = '';
  String rerceiveMessageBody = '';

  FlutterXmpp flutterXmpp;

  @override
  void initState() {
    super.initState();
    initXmpp();
  }


  @override
  void dispose() async{
    await flutterXmpp.stop();
    super.dispose();
  }

  Future<void> initXmpp() async{
    var auth = {
      "user_jid": "papua-dev@0.0.0.0/Android",
      "password":"papua-dev",
      "host":"0.0.0.0",
      "port":5222
    };
    flutterXmpp = new FlutterXmpp(auth);

    // login
    await flutterXmpp.login();

    // start listening receive message
    await flutterXmpp.start(_onReceiveMessage,_onError);

    sleep(const Duration(seconds:2)); // just sample wait for get current state

    print(await flutterXmpp.currentState()); // get current state

    // sending Message
    await flutterXmpp.sendMessage("xbon@0.0.0.0","Kirim Pesan Bro","random_id_for_sync_with_sqlite");


    // read Message
    await flutterXmpp.readMessage("xbon@0.0.0.0","random_id_for_sync_with_sqlite");


    // life cycle, if app not active, kill stream get incoming message ..
    lifeCycle();

    // logout
    await flutterXmpp.logout();

  }

  void lifeCycle() async{
    SystemChannels.lifecycle.setMessageHandler((msg) async{
      if(msg == "AppLifecycleState.inactive" || msg == "AppLifecycleState.suspending" ){
        await flutterXmpp.stop();
      }else if(msg == "AppLifecycleState.resumed"){
        await flutterXmpp.start(_onReceiveMessage, _onError);
      }
      print('SystemChannels> $msg');
      return "Lifecycle";
    });
  }

  void _onReceiveMessage(dynamic event) {
    print(event);
    if(event["type"] == "incoming") {
      setState(() {
        rerceiveMessageFrom = event['from'];
        rerceiveMessageBody = event['body'];
        rerceiveMessageBody = event['id']; // chat ID
      });
    } else {
      setState(() {
        rerceiveMessageFrom = event['to'];
        rerceiveMessageBody = event['body'];
        rerceiveMessageBody = event['id']; // chat ID
      });
    }
  }

  void _onError(Object error) {
    print(error);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('FlutterXMPP'),
        ),
        body: Center(
          child: Text('Incoming or Outgoinng Message: \n$rerceiveMessageFrom\n$rerceiveMessageBody'),
        ),
      ),
    );
  }
}

```
